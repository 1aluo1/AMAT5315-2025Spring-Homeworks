using LinearAlgebra, BenchmarkTools, LinearAlgebra.BLAS

# 原函数（假设原始实现）
function lufact_pivot1_original!(A)
    n = size(A, 1)
    for k in 1:n-1
        # 选主元
        pivot = k-1 + argmax(abs.(@view A[k:end, k]))
        if pivot != k
            # 行交换（原实现）
            A[[k, pivot], :] = A[[pivot, k], :]
        end
        # 消元
        for i in k+1:n
            factor = A[i, k] / A[k, k]
            A[i, k] = factor
            A[i, k+1:end] -= factor * @view A[k, k+1:end]
        end
    end
    return A
end

# 改进后的函数（使用BLAS）
function lufact_pivot1_improved!(A)
    n = size(A, 1)
    temp_row = Vector{eltype(A)}(undef, n)
    for k in 1:n-1
        # 选主元
        pivot = k-1 + argmax(abs.(@view A[k:end, k]))
        if pivot != k
            # 使用BLAS.blascopy!交换行
            BLAS.blascopy!(n, A, pivot, size(A, 1), temp_row, 1)
            BLAS.blascopy!(n, A, k, size(A, 1), A, pivot, size(A, 1))
            BLAS.blascopy!(n, temp_row, 1, A, k, size(A, 1))
        end
        # 消元（使用BLAS.axpy!）
        for i in k+1:n
            factor = A[i, k] / A[k, k]
            A[i, k] = factor
            BLAS.axpy!(-factor, @view(A[k, k+1:n]), @view(A[i, k+1:n]))
        end
    end
    return A
end

# 性能测试
n = 1000
A_orig = rand(n, n)
A_improved = copy(A_orig)

println("原函数时间：")
@btime lufact_pivot1_original!($A_orig)

println("\n改进函数时间：")
@btime lufact_pivot1_improved!($A_improved)