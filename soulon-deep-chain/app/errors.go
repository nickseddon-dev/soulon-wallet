package app

type ErrorCode string

const (
	ErrCodeInvalidTx       ErrorCode = "INVALID_TX"
	ErrCodeInvalidField    ErrorCode = "INVALID_FIELD"
	ErrCodeInvalidVersion  ErrorCode = "INVALID_VERSION"
	ErrCodeExecutionFailed ErrorCode = "EXECUTION_FAILED"
)

type AppError struct {
	Code    ErrorCode
	Message string
}

func (e *AppError) Error() string {
	return string(e.Code) + ": " + e.Message
}

func newInvalidFieldError(message string) error {
	return &AppError{
		Code:    ErrCodeInvalidField,
		Message: message,
	}
}

func newInvalidTxError(message string) error {
	return &AppError{
		Code:    ErrCodeInvalidTx,
		Message: message,
	}
}

func wrapExecutionError(message string) error {
	return &AppError{
		Code:    ErrCodeExecutionFailed,
		Message: message,
	}
}
