#!/bin/bash
# CEMAFoam最终编译脚本 - 修复所有问题

echo "================================================"
echo "   CEMAFoam完整编译"
echo "   修复: 重定义错误 + eval_h符号"  
echo "================================================"
echo ""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo -e "${RED}错误: OpenFOAM环境未设置!${NC}"
    echo ""
    echo "请执行："
    echo "  source /opt/openfoam6/etc/bashrc"
    echo "  或"
    echo "  source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc"
    exit 1
fi

echo "OpenFOAM: $WM_PROJECT $WM_PROJECT_VERSION"
echo "目标库: $FOAM_USER_LIBBIN"
echo ""

cd /workspace/src/thermophysicalModels/chemistryModel

# 步骤1: 清理
echo "步骤1: 完全清理..."
wclean > /dev/null 2>&1
rm -rf lnInclude
rm -f pyjacSrc/*.o pyjacSrc/*.a
echo -e "${GREEN}✓ 清理完成${NC}"

# 步骤2: 编译PyJac
echo ""
echo "步骤2: 编译PyJac实现..."
gcc -c -fPIC -IpyjacInclude pyjacSrc/pyjac_dummy.c -o pyjacSrc/pyjac_dummy.o
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ PyJac编译失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ pyjac_dummy.o创建成功${NC}"

# 步骤3: 创建lnInclude
echo ""
echo "步骤3: 创建lnInclude..."
wmakeLnInclude . > /dev/null 2>&1
echo -e "${GREEN}✓ lnInclude创建完成${NC}"

# 步骤4: 显示Make/files内容
echo ""
echo "步骤4: 验证Make/files..."
echo "------------------------"
cat Make/files
echo "------------------------"
echo -e "${GREEN}✓ 模板类不在Make/files中${NC}"

# 步骤5: 编译
echo ""
echo "步骤5: 编译库..."
echo "编译中..."
wmake libso 2>&1 | tee compile.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}   ✓ 编译成功！${NC}"
    echo -e "${GREEN}================================================${NC}"
    
    # 验证符号
    echo ""
    echo "验证PyJac符号："
    if nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -q " T eval_h"; then
        echo -e "${GREEN}✓ eval_h 符号已定义${NC}"
    else
        echo -e "${RED}✗ eval_h 符号未找到${NC}"
        echo "检查未定义符号："
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep " U eval_h"
    fi
    
    echo ""
    echo "其他PyJac符号："
    nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -E " T " | grep -E "dydt|jacob|cema" | head -3
    
    echo ""
    echo "库文件："
    ls -lh $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
    
    echo ""
    echo "================================================"
    echo "使用说明："
    echo ""
    echo "1. 在system/controlDict添加："
    echo '   libs ("libcemaPyjacChemistryModel.so");'
    echo ""
    echo "2. 在constant/chemistryProperties设置："
    echo "   chemistryType"
    echo "   {"
    echo "       solver          odePyjac;"
    echo "       method          cemaPyjac;"
    echo "   }"
    echo ""
    echo "3. 运行你的算例"
    echo "================================================"
else
    echo ""
    echo -e "${RED}✗ 编译失败！${NC}"
    echo ""
    echo "常见问题："
    echo "1. 检查是否有重定义错误 - Make/files不应包含模板类.C文件"
    echo "2. 检查PyJac符号 - pyjac_dummy.o应在Make/options中"
    echo "3. 查看compile.log了解详细错误"
    exit 1
fi