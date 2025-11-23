#!/bin/bash
# 确保PyJac正确链接的编译脚本

echo "================================================"
echo "   CEMAFoam编译 - 包含PyJac实现"
echo "================================================"
echo ""

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo "错误: OpenFOAM环境未设置!"
    echo ""
    echo "请执行以下命令之一:"
    echo "  source /opt/openfoam6/etc/bashrc"
    echo "  source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc"
    echo "  source /opt/OpenFOAM/OpenFOAM-6/etc/bashrc"
    exit 1
fi

echo "OpenFOAM: $WM_PROJECT $WM_PROJECT_VERSION"
echo "目标库: $FOAM_USER_LIBBIN"
echo ""

cd /workspace/src/thermophysicalModels/chemistryModel

# 1. 清理
echo "步骤1: 清理..."
wclean > /dev/null 2>&1
rm -rf lnInclude
rm -f pyjacSrc/*.o
echo "✓ 清理完成"

# 2. 编译pyjac_dummy.o
echo ""
echo "步骤2: 编译PyJac实现..."
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o
if [ $? -ne 0 ]; then
    echo "✗ PyJac编译失败!"
    exit 1
fi
echo "✓ pyjac_dummy.o 创建成功"

# 3. 创建lnInclude
echo ""
echo "步骤3: 创建lnInclude..."
wmakeLnInclude . > /dev/null 2>&1
echo "✓ lnInclude创建完成"

# 4. 编译OpenFOAM库
echo ""
echo "步骤4: 编译CEMAFoam库..."
echo "------------------------"
wmake libso

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "✓ 编译成功!"
    echo "================================================"
    
    # 验证符号
    echo ""
    echo "验证PyJac符号:"
    if nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -q " T eval_h"; then
        echo "✓ eval_h 符号已找到"
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep " T eval_h"
    else
        echo "✗ 警告: eval_h符号未找到或未定义"
        echo "检查未定义符号:"
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep " U eval_h" | head -3
    fi
    
    echo ""
    echo "其他PyJac符号:"
    nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -E " T " | grep -E "dydt|jacob|cema" | head -3
    
    echo ""
    echo "库位置:"
    ls -lh $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
    
else
    echo ""
    echo "✗ 编译失败!"
    echo "请检查错误信息"
    exit 1
fi

echo ""
echo "================================================"
echo "下一步:"
echo "1. 确保controlDict包含: libs (\"libcemaPyjacChemistryModel.so\");"
echo "2. 运行你的算例"
echo "================================================"