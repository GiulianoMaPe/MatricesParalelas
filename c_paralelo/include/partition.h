#ifndef PARTITION_H
#define PARTITION_H
#include <stddef.h>

/*
 * ============================================================================
 *  Reparto de filas para el hibrido MPI + OpenMP  --  diseno (Sprint 2, I2)
 * ============================================================================
 *
 *  Autor: Integrante 2 (Sebastian).  Fecha: 30/09/2026.
 *  Estado: DISENO. Este archivo es el entregable de Sprint 2 ("Diseno MPI con
 *  ejemplos verificables"). La implementacion entra en Sprint 4
 *  (c_paralelo/src/partition.c, junto con Scatterv/Gatherv de I1); hasta entonces
 *  partition_rows() devuelve PARTITION_PENDING (2); partition_split() solo
 *  esta declarada y tendra implementacion en S4. Ver docs/diagnostico_c_paralelo.md (seccion 6) y
 *  la evidencia de ejecucion en docs/sprints/sprint-02.md.
 *
 *  NOTA DE CODIGO: este fichero es ASCII a proposito (regla de todos los .c/.h
 *  del proyecto: el compilador MSVC trabaja con la pagina de codigos por
 *  defecto y /W4 /WX).
 *
 * ----------------------------------------------------------------------------
 *  1. QUE RESUELVE
 * ----------------------------------------------------------------------------
 *  Repartir N filas entre P procesos MPI (1D block-row partitioning, la decision
 *  adoptada en docs/bibliografia.md) y producir los dos vectores que piden
 *  MPI_Scatterv y MPI_Gatherv:
 *
 *    - counts[]          : tamano del bloque de cada proceso, EN ELEMENTOS
 *                          double (no en filas), como exige docs/contrato.md.
 *    - displacements[]   : desplazamiento inicial de cada bloque, EN ELEMENTOS
 *                          double, acumulado de los counts.
 *
 *  Dos fases, dos funciones, porque tienen unidades y limites distintos:
 *
 *    Fase 1  partition_split()         -> filas por proceso e indice de fila
 *                                         inicial (independiente del tipo de
 *                                         dato; sirve para abrir los buffers
 *                                         locales y para el limite del bucle
 *                                         OpenMP).
 *    Fase 2  partition_rows()          -> counts y desplazamientos MPI
 *                                         (filas * N, con comprobacion de los
 *                                         limites enteros de las API MPI).
 *
 *  Ambas son deterministas: NO llaman a MPI, no usan hilos ni reservan
 *  memoria. Solo escribiran en los vectores del llamador. Se pueden probar sin
 *  inicializar MPI y con cualquier P, incluidos los casos donde P > N.
 *
 * ----------------------------------------------------------------------------
 *  2. ALGORITMO (cociente y resto)
 * ----------------------------------------------------------------------------
 *      q = N / P            (division entera)
 *      r = N % P            (resto, 0 <= r < P)
 *
 *      filas[i]    = q + (i < r ? 1 : 0)      los primeros r procesos reciben
 *                                             una fila extra
 *      primera[i]  = i * q + min(i, r)        indice de la primera fila de i
 *
 *  La forma cerrada de "primera[i]" evita acumular sumas y permite a cada rank
 *  calcular su propio bloque sin comunicacion.  Invariantes que toda ejecucion
 *  debe cumplir (i en [0, P)):
 *
 *      I1  filas[i] >= 0 y suma(filas[i]) == N
 *      I2  primera[0] == 0
 *      I3  primera[i+1] == primera[i] + filas[i]         (bloques contiguos)
 *      I4  primera[i] + filas[i] <= N
 *      I5  counts[i] == filas[i] * N                     (elementos double)
 *      I6  displs[i]  == primera[i] * N
 *      I7  suma(counts[i]) == N * N                      (toda la matriz)
 *      I8  displs[i] + counts[i] == displs[i+1], y
 *          displs[P-1] + counts[P-1] == N * N
 *
 *  Caso P > N: q = 0 y r = N, de modo que los primeros N procesos reciben 1
 *  fila y los P - N restantes reciben 0 filas (count 0). MPI acepta entradas
 *  con count 0 en Scatterv/Gatherv; no es un error y no bloquea a nadie.
 *
 * ----------------------------------------------------------------------------
 *  3. LIMITES Y CODIGOS DE RETORNO
 * ----------------------------------------------------------------------------
 *  Precondiciones (si alguna falla: retorno 1, sin escribir en los vectores):
 *
 *      - n >= 1 y processes >= 1                 (contrato: N > 0, P >= 1)
 *      - punteros no nulos
 *      - partition_split: n <= INT_MAX (filas e indices se guardan en int)
 *      - partition_rows: n * n sin desbordar size_t
 *      - partition_rows: n * n <= INT_MAX -> N <= 46340 (counts y desplazamientos
 *                                                  de las colectivas variables
 *                                                  son int en MPI)
 *
 *  La restriccion util es n*n <= INT_MAX porque el ultimo desplazamiento mas su
 *  count es exactamente N*N; comprobarlo una vez cubre todos los vectores.
 *  46340^2 = 2147395600 <= 2147483647 (INT_MAX)  -> admitido.
 *  46341^2 = 2147488281 >  2147483647           -> rechazado, jamas truncado.
 *  En la practica el limite real sera antes la RAM: N dobles por matriz son
 *  8*N^2 bytes (N=46340 -> ~17 GB por matriz).
 *
 *  Retorno:
 *      PARTITION_OK (0)        vectores rellenados y invariantes cumplidos
 *      PARTITION_INVALID (1)   precondicion violada; vectores intactos
 *      PARTITION_PENDING (2)   modulo sin implementar (estado actual)
 *
 *  El reparto se calcula con el mismo algoritmo en todos los ranks, por lo que
 *  no hace falta reducirlo por MPI; si el caller quiere cerrar el diseno debe
 *  comparar processes con MPI_Comm_size(MPI_COMM_WORLD) antes de llamar.
 *
 * ----------------------------------------------------------------------------
 *  4. EJEMPLOS RESUELTOS  (N no divisible entre P y procesos sin filas)
 * ----------------------------------------------------------------------------
 *  Notacion: filas = filas por proceso; ini = primera fila; counts y displs en
 *  elementos double (multiples de N).
 *
 *  (a) N=10, P=4   q=2, r=2   NO divisible
 *      filas  [3 3 2 2]   suma 10
 *      ini    [0 3 6 8]
 *      counts [30 30 20 20] suma 100 = 10^2
 *      displs [0 30 60 80]  80+20 = 100
 *
 *  (b) N=7, P=3    q=2, r=1   NO divisible
 *      filas  [3 2 2]      suma 7
 *      ini    [0 3 5]
 *      counts [21 14 14]   suma 49 = 7^2
 *      displs [0 21 35]    35+14 = 49
 *
 *  (c) N=5, P=2    q=2, r=1   NO divisible
 *      filas  [3 2]        ini [0 3]
 *      counts [15 10]      displs [0 15]    suma 25 = 5^2
 *
 *  (d) N=8, P=4    q=2, r=0   divisible
 *      filas  [2 2 2 2]    ini [0 2 4 6]
 *      counts [16 16 16 16] displs [0 16 32 48]   suma 64 = 8^2
 *
 *  (e) N=2, P=2    q=1, r=0   caso de la prueba --smoke-test (2x2)
 *      filas  [1 1]        ini [0 1]
 *      counts [2 2]        displs [0 2]     suma 4 = 2^2
 *
 *  (f) N=1, P=1    dimension minima
 *      filas  [1]          ini [0]
 *      counts [1]          displs [0]       suma 1 = 1^2
 *
 *  (g) N=3, P=5    P > N: DOS PROCESOS SIN FILAS
 *      q=0, r=3
 *      filas  [1 1 1 0 0]  suma 3
 *      ini    [0 1 2 3 3]  los ranks 3 y 4 apuntan al final (3*3 = 9)
 *      counts [3 3 3 0 0]  suma 9 = 3^2     (count 0 admitido por MPI)
 *      displs [0 3 6 9 9]
 *
 *  (h) N=4, P=8    P > N: CUATRO PROCESOS SIN FILAS
 *      q=0, r=4
 *      filas  [1 1 1 1 0 0 0 0]            ini [0 1 2 3 4 4 4 4]
 *      counts [4 4 4 4 0 0 0 0]  suma 16   displs [0 4 8 12 16 16 16 16]
 *
 *  (i) Limites: N=46340 -> PARTITION_OK (N*N = 2147395600 <= INT_MAX)
 *               N=46341 -> PARTITION_INVALID (N*N = 2147488281 > INT_MAX)
 *
 *  Los ejemplos (a)-(i) son la lista de casos que debe reprobar la prueba
 *  unitaria de particion en Sprint 4/5.  La verificacion aritmetica ejecutada
 *  el 30/09/2026 y su comando de reproduccion estan en
 *  docs/sprints/sprint-02.md (apartado "Pruebas y evidencias").
 *
 * ----------------------------------------------------------------------------
 *  5. COMO SE USA EN main.c  (esquema, Sprint 4)
 * ----------------------------------------------------------------------------
 *      int *filas = malloc(P * sizeof *filas);      // sin VLA: MSVC no admite
 *      int *ini   = malloc(P * sizeof *ini);        // arreglos de tamano variable
 *      int *cnt   = malloc(P * sizeof *cnt);
 *      int *dsp   = malloc(P * sizeof *dsp);
 *      if (partition_split(N, P, filas, ini)  != PARTITION_OK) -> error
 *      if (partition_rows(N, P, cnt, dsp)     != PARTITION_OK) -> error
 *
 *      // solo el hilo inicial, fuera de OpenMP:
 *      MPI_Bcast(B, N * N, MPI_DOUBLE, 0, MPI_COMM_WORLD);
 *      MPI_Scatterv(A, cnt, dsp, MPI_DOUBLE,
 *                   local_a, filas[rank] * N, MPI_DOUBLE, 0, MPI_COMM_WORLD);
 *
 *      #pragma omp parallel for schedule(static)      // indice con signo
 *      for (int i = 0; i < filas[rank]; ++i) { ... }   // filas locales de C
 *
 *      MPI_Gatherv(local_c, filas[rank] * N, MPI_DOUBLE,
 *                  C, cnt, dsp, MPI_DOUBLE, 0, MPI_COMM_WORLD);
 *
 *  Notas de diseno ligadas a este uso:
 *   - Los vectores los reserva el llamador con "processes" entradas; nadie los
 *     libera dentro de estas funciones.
 *   - filas[rank]*N es tambien el tamano de recvcount local: si filas[rank] == 0
 *     se envia/coge 0 elementos, nunca un puntero invalido (reservar 1 entrada
 *     de seguridad o permitir NULL cuando el tamano es 0).
 *   - En MSVC el bucle OpenMP usa int con signo (guia, seccion "Memoria y
 *     errores"); por eso los tamanos se propagan como int, no como size_t.
 *   - Si un rank detecta fallo irrecuperable: decision colectiva (p. ej.
 *     MPI_Allreduce) o MPI_Abort; nunca retorno silencioso de un solo rank.
 *   - partition_* no llama a MPI: cualquier error de argumentos se detecta antes
 *     de entrar en una colectiva y evita esperas indefinidas.
 *
 * ----------------------------------------------------------------------------
 *  6. REPRODUCCION DEL CALCULO (para revisores)
 * ----------------------------------------------------------------------------
 *  En PowerShell, desde la raiz del proyecto (aritmetica entera, sin MPI):
 *
 *      foreach ($c in @(@(10,4),@(7,3),@(5,2),@(8,4),@(2,2),@(1,1),@(3,5),@(4,8))) {
 *        $n=$c[0]; $p=$c[1]; $q=[math]::Floor($n/$p); $r=$n%$p
 *        $rows=0..($p-1) | ForEach-Object { $q + [int]($_ -lt $r) }
 *        $first=0..($p-1) | ForEach-Object { $_*$q + [math]::Min($_,$r) }
 *        $cnt=$rows | ForEach-Object { $_*$n }
 *        $dsp=$first | ForEach-Object { $_*$n }
 *        "N=$n P=$p filas=[$($rows -join ' ')] ini=[$($first -join ' ')] " +
 *        "counts=[$($cnt -join ' ')] sum=$((($cnt | Measure-Object -Sum).Sum)) " +
 *        "displs=[$($dsp -join ' ')]"
 *      }
 *
 *  La salida debe coincidir caracter a caracter con los ejemplos (a)-(h).
 * ============================================================================
 */

#define PARTITION_OK      0   /* vectores rellenados e invariantes I1-I8 */
#define PARTITION_INVALID 1   /* precondicion violada; vectores intactos  */
#define PARTITION_PENDING 2   /* igual que MATRIX_PENDING (contrato 0/1/2) */

/* floor(sqrt(INT_MAX)): mayor N admisible por los counts/desplazamientos int
 * de MPI_Scatterv/MPI_Gatherv.  46340^2 = 2147395600; 46341^2 ya desborda. */
#define PARTITION_MAX_N ((size_t)46340)

/*
 * Fase 1: reparto en filas (unidades de fila, independiente de MPI).
 *   rows[i]        filas asignadas al proceso i       (0 <= rows[i] <= n)
 *   first_rows[i]  indice global de su primera fila   (0 <= first_rows[i] <= n)
 * Devuelve PARTITION_OK, PARTITION_INVALID (n < 1, n > INT_MAX,
 * processes < 1, puntero nulo)
 * o PARTITION_PENDING.  El llamador reserva "processes" entradas en cada vector.
 */
int partition_split(size_t n, int processes, int *rows, int *first_rows);

/*
 * Fase 2: counts y desplazamientos para MPI_Scatterv / MPI_Gatherv, EN
 * ELEMENTOS double (counts[i] = rows[i]*N, displacements[i] = first[i]*N).
 * Precondiciones adicionales: n*n sin desbordar size_t y n*n <= INT_MAX
 * (equivalente: n <= PARTITION_MAX_N).  Devuelve PARTITION_OK,
 * PARTITION_INVALID o PARTITION_PENDING.
 * Prototipo original del esqueleto: se conserva la firma para no romper
 * src/partition.c hasta su implementacion en Sprint 4.
 */
int partition_rows(size_t n, int processes, int *counts, int *displacements);

#endif
