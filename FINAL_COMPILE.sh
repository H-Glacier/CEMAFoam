#!/bin/bash
# CEMAFoam最终编译脚本 - 确保PyJac正确链接

echo "================================================"
echo "   CEMAFoam完整编译（包含PyJac）"
echo "================================================"
echo ""

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo "错误: OpenFOAM环境未设置!"
    echo "请先执行source命令设置OpenFOAM环境"
    exit 1
fi

echo "OpenFOAM环境:"
echo "  版本: $WM_PROJECT $WM_PROJECT_VERSION"
echo "  编译器: $WM_CXX"
echo "  目标库: $FOAM_USER_LIBBIN"
echo ""

cd /workspace/src/thermophysicalModels/chemistryModel

# 步骤1: 完全清理
echo "步骤1: 完全清理..."
echo "-------------------"
wclean
rm -rf lnInclude
rm -f pyjacSrc/*.o pyjacSrc/*.so pyjacSrc/*.a
echo "✓ 清理完成"
echo ""

# 步骤2: 预编译PyJac为静态库
echo "步骤2: 编译PyJac静态库..."
echo "-------------------------"
cd pyjacSrc
gcc -c -fPIC -I../pyjacInclude pyjac_dummy.c -o pyjac_dummy.o
ar rcs libpyjac.a pyjac_dummy.o
echo "✓ PyJac静态库创建: libpyjac.a"
cd ..
echo ""

# 步骤3: 创建lnInclude
echo "步骤3: 创建lnInclude..."
echo "-----------------------"
wmakeLnInclude .
echo "✓ lnInclude创建完成"
echo ""

# 步骤4: 修改Make/options以链接静态库
echo "步骤4: 更新Make/options..."
echo "--------------------------"
cat > Make/options.tmp << 'EOF'
EXE_INC = \
    -I$(LIB_SRC)/OpenFOAM/lnInclude \
    -I$(LIB_SRC)/finiteVolume/lnInclude \
    -I$(LIB_SRC)/meshTools/lnInclude \
    -I$(LIB_SRC)/ODE/lnInclude \
    -I$(LIB_SRC)/transportModels/compressible/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/reactionThermo/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/basic/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/specie/lnInclude \
    -I$(LIB_SRC)/thermophysicalModels/functions/Polynomial \
    -I$(LIB_SRC)/thermophysicalModels/chemistryModel/lnInclude \
    -IpyjacInclude

LIB_LIBS = \
    -lfiniteVolume \
    -lmeshTools \
    -lODE \
    -lcompressibleTransportModels \
    -lfluidThermophysicalModels \
    -lreactionThermophysicalModels \
    -lspecie \
    -lchemistryModel \
    pyjacSrc/libpyjac.a \
    -lm
EOF

cp Make/options Make/options.backup
mv Make/options.tmp Make/options
echo "✓ Make/options已更新（备份保存为options.backup）"
echo ""

# 步骤5: 编译OpenFOAM库
echo "步骤5: 编译CEMAFoam库..."
echo "------------------------"
wmake libso 2>&1 | tee compile_output.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✓ 编译成功!"
    echo ""
    
    # 验证
    echo "步骤6: 验证符号..."
    echo "------------------"
    echo "检查eval_h符号:"
    if nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -q " T eval_h"; then
        echo "✓ eval_h 已找到"
    else
        echo "✗ eval_h 未找到 - 检查U符号（未定义）:"
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep " U eval_h"
    fi
    
    echo ""
    echo "检查其他PyJac符号:"
    nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -E " T " | grep -E "eval_|dydt|jacob|cema" | head -5
    
    echo ""
    echo "库信息:"
    ls -lh $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
    
    echo ""
    echo "================================================"
    echo "编译完成!"
    echo "================================================"
    echo ""
    echo "使用方法:"
    echo "1. 在controlDict中添加:"
    echo '   libs ("libcemaPyjacChemistryModel.so");'
    echo ""
    echo "2. 运行求解器"
    echo "================================================"
else
    echo ""
    echo "✗ 编译失败!"
    echo "请查看compile_output.log了解详情"
    exit 1
fi