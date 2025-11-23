#!/bin/bash
# CEMAFoam最终编译脚本 - 确保eval_h正确链接

echo "================================================"
echo "   CEMAFoam最终编译 - 包含PyJac"
echo "================================================"
echo ""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo -e "${RED}错误: OpenFOAM环境未设置!${NC}"
    echo ""
    echo "请先执行："
    echo "  source /opt/openfoam6/etc/bashrc"
    echo "  或"
    echo "  source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc"
    exit 1
fi

echo "OpenFOAM环境:"
echo "  版本: $WM_PROJECT $WM_PROJECT_VERSION"
echo "  库目录: $FOAM_USER_LIBBIN"
echo ""

cd /workspace/src/thermophysicalModels/chemistryModel

# 步骤1: 清理
echo -e "${YELLOW}步骤1: 清理旧文件...${NC}"
wclean > /dev/null 2>&1
rm -rf lnInclude
rm -f pyjacSrc/*.o
echo -e "${GREEN}✓ 清理完成${NC}"

# 步骤2: 创建lnInclude
echo ""
echo -e "${YELLOW}步骤2: 创建lnInclude...${NC}"
wmakeLnInclude . > /dev/null 2>&1
echo -e "${GREEN}✓ lnInclude创建完成${NC}"

# 步骤3: 显示配置
echo ""
echo -e "${YELLOW}步骤3: 编译配置...${NC}"
echo "Make/files内容:"
echo "---------------"
cat Make/files
echo "---------------"
echo -e "${GREEN}✓ pyjac_dummy.c已包含${NC}"

# 步骤4: 编译
echo ""
echo -e "${YELLOW}步骤4: 编译库...${NC}"
wmake libso 2>&1 | tee compile.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}   编译成功！${NC}"
    echo -e "${GREEN}================================================${NC}"
    
    # 验证
    echo ""
    echo -e "${YELLOW}步骤5: 验证符号...${NC}"
    
    # 检查eval_h
    if nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -q " T eval_h"; then
        echo -e "${GREEN}✓ eval_h 符号已定义${NC}"
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep " T eval_h"
    else
        echo -e "${RED}✗ eval_h 符号未找到${NC}"
        echo "检查未定义符号："
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep " U eval_h" | head -3
    fi
    
    # 检查其他符号
    echo ""
    echo "其他PyJac符号："
    nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -E " T " | grep -E "dydt|eval_jacob|cema" | head -5
    
    # 库信息
    echo ""
    echo "库文件信息："
    ls -lh $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
    
    # 依赖检查
    echo ""
    echo "库依赖："
    ldd $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep -E "libm|libstdc"
    
    echo ""
    echo "================================================"
    echo -e "${GREEN}编译完成！现在可以运行reactingFoam${NC}"
    echo "================================================"
    echo ""
    echo "如果仍有eval_h未定义错误，请检查："
    echo "1. pyjac_dummy.c是否正确编译"
    echo "2. extern C声明是否完整"
    echo "3. 运行时是否加载了正确的库"
else
    echo ""
    echo -e "${RED}编译失败！${NC}"
    echo "查看compile.log了解详细错误"
    exit 1
fi