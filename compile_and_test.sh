#!/bin/bash

echo "==========================================
CEMAFoam PyJac 段错误修复脚本
==========================================

问题分析：
- Dimix 函数在访问物种输运属性时越界
- 这是由于 hePsiThermo 类初始化时的兼容性问题

修复方案：
1. 修改 thermophysicalProperties 中的 transport 类型
2. 添加构造函数中的边界检查
3. 重新编译库
==========================================
"

# 设置 OpenFOAM 环境变量
if [ -f /opt/openfoam10/etc/bashrc ]; then
    source /opt/openfoam10/etc/bashrc
elif [ -f $HOME/OpenFOAM/OpenFOAM-v2006/etc/bashrc ]; then
    source $HOME/OpenFOAM/OpenFOAM-v2006/etc/bashrc
else
    echo "警告：未找到 OpenFOAM 环境配置文件"
fi

# 编译库
echo "开始编译 cemaPyjacChemistryModel 库..."
cd /workspace/src/thermophysicalModels/chemistryModel
wmake libso

if [ $? -eq 0 ]; then
    echo "编译成功！"
else
    echo "编译失败，请检查错误信息"
    exit 1
fi

echo "
==========================================
测试建议：
==========================================

1. 使用修改后的 thermophysicalProperties 文件：
   cp /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties.fixed \\
      /workspace/tutorials/premixedFlame1D/constant/thermophysicalProperties

2. 或者尝试以下配置组合：
   
   选项 A - 使用常数输运属性：
   transport       const;
   
   选项 B - 使用多项式输运属性：
   transport       polynomial;
   
   选项 C - 禁用 Dimix 计算：
   在 chemistryProperties 中添加：
   calculateDimix  false;

3. 运行测试：
   cd /workspace/tutorials/premixedFlame1D
   blockMesh
   ./Allrun

如果仍有问题，请检查：
- PyJac 生成的机理文件是否完整
- 所有物种是否都有对应的热物理属性
==========================================
"