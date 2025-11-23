# CEMAFoam编译说明

## 快速编译步骤

### 1. 设置OpenFOAM环境

根据你的OpenFOAM版本，执行相应的source命令：

```bash
# OpenFOAM v2006
source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc

# 或者 OpenFOAM v6
source /opt/openfoam6/etc/bashrc
```

### 2. 运行完整编译脚本

```bash
cd /workspace
./full_compile.sh
```

这个脚本会自动：
- 构建PyJac dummy库
- 清理旧的编译文件
- 编译CEMAFoam化学模型库
- 验证编译结果

### 3. 验证编译

成功编译后，你应该看到：
```
BUILD SUCCESSFUL!
Library created at: /home/your_user/OpenFOAM/your_user-6/platforms/linux64GccDPInt32Opt/lib/libcemaPyjacChemistryModel.so
```

## 手动编译步骤（如果自动脚本失败）

### Step 1: 构建PyJac库
```bash
cd /workspace/src/thermophysicalModels/chemistryModel
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o
ar rcs pyjacSrc/libpyjac_dummy.a pyjacSrc/pyjac_dummy.o
gcc -shared -o pyjacSrc/libpyjac_dummy.so pyjacSrc/pyjac_dummy.o -lm
```

### Step 2: 编译OpenFOAM库
```bash
wclean
wmakeLnInclude .
wmake libso
```

## 在你的算例中使用

### 1. 更新system/controlDict

添加库到你的controlDict文件：
```
libs
(
    "libcemaPyjacChemistryModel.so"
);
```

### 2. 更新constant/chemistryProperties

确保使用正确的化学模型：
```
chemistryType
{
    solver          odePyjac;
    method          cemaPyjac;
}
```

## 关于反应数

程序现在会显示两个反应数：
1. **OpenFOAM反应文件中的反应数**：从reactions文件读取（可能较少）
2. **PyJac机理中的反应数**：325个（从mechanism.h定义）

实际计算时，PyJac会使用自己的325个反应机理，而不是OpenFOAM的反应文件。

## 故障排除

### 问题：undefined symbol: eval_h

**解决方案**：
1. 确保PyJac dummy库已编译：
   ```bash
   ls -la /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/*.so
   ```

2. 重新运行完整编译脚本：
   ```bash
   ./full_compile.sh
   ```

### 问题：找不到库文件

**解决方案**：
检查库路径：
```bash
echo $FOAM_USER_LIBBIN
ls -la $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
```

### 问题：反应数不匹配

这是正常的。PyJac使用自己的机理文件（325个反应），独立于OpenFOAM的reactions文件。

## 生产环境使用

⚠️ **重要**：当前使用的是PyJac的dummy实现，仅用于测试。

对于生产环境，你需要：
1. 使用PyJac生成真实的化学动力学代码：
   ```bash
   pyjac -l c -i your_mechanism.yaml
   ```

2. 替换dummy文件：
   ```bash
   cp *.c /workspace/src/thermophysicalModels/chemistryModel/pyjacSrc/
   ```

3. 重新编译：
   ```bash
   ./full_compile.sh
   ```

## 验证运行

编译成功后，运行测试：
```bash
cd your_case_directory
reactingFoam
```

你应该看到类似输出：
```
cemaPyjacChemistryModel: Starting initialization...
  Thermo type: hePsiThermo<reactingMixture<...>>
  Number of species detected: 53
  Number of reactions: 53
  Y_ size: 53
cemaPyjacChemistryModel: Number of species = 53 (PyJac NSP = 53)
cemaPyjacChemistryModel: OpenFOAM reactions from file = 53
cemaPyjacChemistryModel: PyJac mechanism parameters:
  Forward reactions = 325
  Reversible reactions = 309
  Pressure-dependent reactions = 41
cemaPyjacChemistryModel: Number of elements = 5
Note: PyJac will use its own reaction mechanism (325 reactions), not OpenFOAM's file

 Evaluating species enthalpy of formation using PyJac
```