#!/bin/bash
# 简单直接的编译脚本

echo "============================================="
echo "CEMAFoam编译脚本"
echo "============================================="

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo "错误: OpenFOAM环境未设置!"
    echo "请先执行:"
    echo "  source /path/to/OpenFOAM/etc/bashrc"
    exit 1
fi

echo "使用OpenFOAM: $WM_PROJECT $WM_PROJECT_VERSION"
echo "目标库目录: $FOAM_USER_LIBBIN"
echo ""

cd /workspace/src/thermophysicalModels/chemistryModel

# 清理
echo "清理旧文件..."
wclean

# 创建lnInclude
echo "创建lnInclude..."
wmakeLnInclude .

# 编译
echo "编译库文件..."
wmake libso

# 检查结果
if [ $? -eq 0 ]; then
    echo ""
    echo "============================================="
    echo "编译成功!"
    echo "============================================="
    echo "库文件位置: $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so"
    echo ""
    echo "检查eval_h符号:"
    nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep eval_h
    if [ $? -eq 0 ]; then
        echo "✓ eval_h符号已找到"
    else
        echo "✗ 警告: eval_h符号未找到"
    fi
else
    echo ""
    echo "编译失败!"
    exit 1
fi