
public typealias Completion = () -> Void
public typealias ErrorCompletion<ErrorType> = (_ error : ErrorType?) -> ()
public typealias DataCompletion<DataType, ErrorType> = (_ data: DataType, _ error: ErrorType?) -> ()
