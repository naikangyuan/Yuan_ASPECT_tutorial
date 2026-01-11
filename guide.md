---
layout: default
title: 使用指南
nav_order: 2
---

# 指南内容
...
## ASPECT 安装指南 (基于 Linux/Candi)

本文档将指导你在 Linux 系统下从源码编译安装地幔对流模拟软件 ASPECT。我们将使用 Candi 自动构建底层依赖库 deal.II。
### 1. 准备工作与 OpenMPI 安装

在开始之前，请确保你的系统已经安装了基础的编译工具（如 gcc, g++, gfortran, make, cmake 等）。

ASPECT 需要并行计算支持，因此首先需要安装 MPI 库。这里以 OpenMPI 为例。
1.1 安装 OpenMPI

假设你已经下载并编译安装了 OpenMPI（例如版本 5.0.5），安装路径为 /home/yuan/mpi/openmpi-5.0.5。
1.2 配置环境变量

安装完成后，必须将 MPI 的可执行文件和库文件路径添加到环境变量中，否则后续的 Candi 和 ASPECT 将无法找到并行编译器。

打开你的终端配置文件（如 ~/.bashrc 或 ~/.zshrc），添加以下内容：
code Bash

    
#################################
# OpenMPI Environment Configuration
#################################
export MPI_HOME=/home/yuan/mpi/openmpi-5.0.5
export PATH=$MPI_HOME/bin:$PATH
# 注意：确保 LD_LIBRARY_PATH 语法正确，保留原有路径
export LD_LIBRARY_PATH=$MPI_HOME/lib:$LD_LIBRARY_PATH

  

保存并退出，然后使配置生效：
code Bash

    
source ~/.bashrc

  

验证： 输入 mpicc --version 和 mpicxx --version，确保输出的是你刚安装的版本。
### 2. 使用 Candi 自动安装 deal.II 及依赖

ASPECT 严重依赖 deal.II 库及其生态系统（Trilinos, PETSc, p4est 等）。我们将使用 Candi 脚本来自动化这个复杂的编译过程。
2.1 获取 Candi

创建一个工作目录并克隆 Candi：
code Bash

    
mkdir -p ~/fem4
cd ~/fem4
git clone https://github.com/dealii/candi.git
cd candi

  

2.2 配置 candi.cfg

candi.cfg 文件决定了我们要安装哪些包。ASPECT 对依赖包有特定要求（通常需要 Trilinos, p4est, PETSc, HDF5 等）。

使用文本编辑器打开 candi.cfg，修改 PACKAGES 列表。
注意： 下面的配置注释掉了非必须包，保留了 ASPECT 推荐的包。
code Bash

    
vim candi.cfg

  

修改内容如下：
code Bash

    
 Now we pick the packages to install:
PACKAGES="load:dealii-prepare"

#--- System dependencies (通常系统已预装，如果报错请取消注释) ---
#PACKAGES="${PACKAGES} once:zlib"
#PACKAGES="${PACKAGES} once:bzip2"
#PACKAGES="${PACKAGES} once:git"
#PACKAGES="${PACKAGES} once:cmake"
#PACKAGES="${PACKAGES} once:openblas"

#--- Optional Tools ---
#PACKAGES="${PACKAGES} once:astyle"
#PACKAGES="${PACKAGES} once:numdiff"

#--- Packages for ASPECT / deal.II Active Components ---
#PACKAGES="${PACKAGES} once:adolc"
#PACKAGES="${PACKAGES} once:arpack-ng"
#PACKAGES="${PACKAGES} once:assimp"
#PACKAGES="${PACKAGES} once:ginkgo"
#PACKAGES="${PACKAGES} once:gmsh"
#PACKAGES="${PACKAGES} once:gsl"
#PACKAGES="${PACKAGES} once:mumps"
#PACKAGES="${PACKAGES} once:opencascade"

#[必须] 并行网格划分依赖
PACKAGES="${PACKAGES} once:parmetis"

#[推荐] 时间步进求解器
PACKAGES="${PACKAGES} once:sundials"

#[必须] 数据输出格式支持
PACKAGES="${PACKAGES} once:hdf5"
#PACKAGES="${PACKAGES} once:netcdf"

 [必须] 并行自适应网格库
PACKAGES="${PACKAGES} once:p4est"

#PACKAGES="${PACKAGES} once:kokkos once:kokkoskernels"

[必须] 线性代数求解器 (Trilinos 是 ASPECT 的核心依赖之一)
PACKAGES="${PACKAGES} once:trilinos"

#PACKAGES="${PACKAGES} once:hypre"

[推荐] 另一个强大的线性代数求解器库
PACKAGES="${PACKAGES} once:petsc"
PACKAGES="${PACKAGES} once:slepc"

[可选] 符号计算引擎
PACKAGES="${PACKAGES} once:symengine"

[必须] 最终的主程序库
PACKAGES="${PACKAGES} dealii"

  

2.3 开始编译

设置安装路径（可选，默认在当前目录）并运行安装脚本。建议使用 -j 参数开启多核编译以加快速度（例如使用 4 核）。
code Bash

    
#运行安装，-j4 代表用4个核心编译
./candi.sh -j4 

  

2.4 编译完成与环境激活

编译过程可能需要数小时（取决于 Trilinos 和 deal.II 的编译速度）。成功完成后，终端会输出类似以下信息：
code Text

    
dealii.git has now been installed in

    /home/yuan/fem4/dealii-candi/deal.II-v9.7.0

To update your environment variables, use the created modulefile:

    /home/yuan/fem4/dealii-candi/configuration/modulefiles/default

If you are not using modules, execute the following command instead:

    source /home/yuan/fem4/dealii-candi/configuration/deal.II-v9.7.0

To export environment variables for all installed libraries execute:

    source /home/yuan/fem4/dealii-candi/configuration/enable.sh

Build finished in 11311 seconds.
...

  

关键步骤： 为了让 ASPECT 找到刚才安装的所有库，必须执行 Candi 生成的 enable.sh 脚本。
code Bash

    
#将此命令添加到你的终端配置文件中，或者每次编译前手动运行
source /home/yuan/fem4/dealii-candi/configuration/enable.sh

  

### 3. 安装 ASPECT

依赖库准备好后，就可以编译 ASPECT 了。
3.1 获取 ASPECT 源码
code Bash

    
cd ~/fem4
git clone https://github.com/geodynamics/aspect.git
cd aspect

  

3.2 编译 ASPECT

ASPECT 使用 CMake 进行构建。

    加载环境（如果之前没做）：
    code Bash

    
source /home/yuan/fem4/dealii-candi/configuration/enable.sh

  

创建构建目录：
code Bash

    
mkdir build
cd build

  

配置与生成 Makefile：
code Bash

    
cmake ..

  

此时注意观察输出，CMake 应该能自动识别到 deal.II 的路径以及 Trilinos, p4est 等组件。如果报错提示找不到 deal.II，请检查上一步 source 是否执行成功。

开始编译：
code Bash

        
    make -j4

      

3.3 验证安装

编译完成后，会在 build 目录下生成 aspect 可执行文件。你可以运行自带的测试用例来验证安装：
code Bash

    
#运行一个简单的测试
./aspect ../cookbooks/shell_simple_2d/shell_simple_2d.prm

  

如果模拟开始运行并输出时间步信息，恭喜你，ASPECT 安装成功！
