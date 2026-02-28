#include <cuda_runtime.h>
#include <iostream>
#include <vector>

#define TILE_WIDTH 16
#define MAX_FILTER_WIDTH 64

// 常量内存中的二维卷积核（最大 64x64），可直接按 F[fRow][fCol] 访问
__constant__ float F[MAX_FILTER_WIDTH][MAX_FILTER_WIDTH];

__global__ void convolution_2D_const_mem_kernel(const float *N, float *P, int r,
                                                 int width, int height,
                                                 int filterWidth) {
    int outCol = blockIdx.x * blockDim.x + threadIdx.x;
    int outRow = blockIdx.y * blockDim.y + threadIdx.y;

    if (outCol >= width || outRow >= height) {
        return;
    }

    float Pvalue = 0.0f;

    for (int fRow = 0; fRow < filterWidth; fRow++) {
        for (int fCol = 0; fCol < filterWidth; fCol++) {
            int inRow = outRow - r + fRow;
            int inCol = outCol - r + fCol;
            if (inRow >= 0 && inRow < height && inCol >= 0 && inCol < width) {
                // 按你给的写法：F[fRow][fCol] 来自 constant memory
                Pvalue += F[fRow][fCol] * N[inRow * width + inCol];
            }
        }
    }

    P[outRow * width + outCol] = Pvalue;
}

static void checkCuda(cudaError_t result, const char *msg) {
    if (result != cudaSuccess) {
        std::cerr << "CUDA Error (" << msg << "): " << cudaGetErrorString(result) << std::endl;
        std::exit(EXIT_FAILURE);
    }
}

int main() {
    const int width = 8;
    const int height = 8;

    const int r = 1;
    const int filterWidth = 2 * r + 1;

    if (filterWidth > MAX_FILTER_WIDTH) {
        std::cerr << "Filter width exceeds constant memory buffer." << std::endl;
        return EXIT_FAILURE;
    }

    const size_t imageBytes = width * height * sizeof(float);

    std::vector<float> h_N(width * height);
    std::vector<float> h_P(width * height, 0.0f);
    std::vector<float> h_F(filterWidth * filterWidth);

    for (int i = 0; i < width * height; ++i) {
        h_N[i] = static_cast<float>(i % 16);
    }

    for (int i = 0; i < filterWidth * filterWidth; ++i) {
        h_F[i] = 1.0f / 9.0f;
    }

    float *d_N = nullptr;
    float *d_P = nullptr;
    checkCuda(cudaMalloc(&d_N, imageBytes), "cudaMalloc d_N");
    checkCuda(cudaMalloc(&d_P, imageBytes), "cudaMalloc d_P");

    checkCuda(cudaMemcpy(d_N, h_N.data(), imageBytes, cudaMemcpyHostToDevice), "cudaMemcpy h_N -> d_N");

    // 拷贝到二维 constant memory 的左上角区域：F[0:filterWidth-1][0:filterWidth-1]
    checkCuda(cudaMemcpyToSymbol(F, h_F.data(),
                                 filterWidth * filterWidth * sizeof(float),
                                 0, cudaMemcpyHostToDevice),
              "cudaMemcpyToSymbol F");

    dim3 blockDim(TILE_WIDTH, TILE_WIDTH);
    dim3 gridDim((width + blockDim.x - 1) / blockDim.x,
                 (height + blockDim.y - 1) / blockDim.y);

    convolution_2D_const_mem_kernel<<<gridDim, blockDim>>>(d_N, d_P, r, width, height, filterWidth);
    checkCuda(cudaGetLastError(), "kernel launch");
    checkCuda(cudaDeviceSynchronize(), "kernel execution");

    checkCuda(cudaMemcpy(h_P.data(), d_P, imageBytes, cudaMemcpyDeviceToHost), "cudaMemcpy d_P -> h_P");

    std::cout << "Convolution output (first 4x4):\n";
    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 4; ++col) {
            std::cout << h_P[row * width + col] << "\t";
        }
        std::cout << '\n';
    }

    cudaFree(d_N);
    cudaFree(d_P);

    return 0;
}
