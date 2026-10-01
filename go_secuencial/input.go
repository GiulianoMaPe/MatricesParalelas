package main

// Generate requiere un N válido y una semilla uint32 (incluidos 0 y 4294967295).
// Valida el tamaño antes de devolver ErrPending; la generación sigue pendiente.
func Generate(n int, seed uint32) (Matrix, Matrix, error) {
	if err := ValidateDimension(n); err != nil {
		return Matrix{}, Matrix{}, err
	}
	return Matrix{}, Matrix{}, ErrPending
}
