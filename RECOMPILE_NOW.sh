#!/bin/bash
# 最终编译脚本 - 确保eval_h被正确编译

echo "================================================"
echo "   CEMAFoam最终编译脚本"
echo "================================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查OpenFOAM环境
if [ -z "$WM_PROJECT" ]; then
    echo -e "${RED}错误: OpenFOAM环境未设置!${NC}"
    echo ""
    echo "请执行以下命令之一："
    echo -e "${YELLOW}  source /opt/openfoam6/etc/bashrc${NC}"
    echo -e "${YELLOW}  source /opt/OpenFOAM/OpenFOAM-v2006/etc/bashrc${NC}"
    echo -e "${YELLOW}  source /opt/OpenFOAM/OpenFOAM-6/etc/bashrc${NC}"
    exit 1
fi

echo -e "${GREEN}✓ OpenFOAM环境已设置${NC}"
echo "  版本: $WM_PROJECT $WM_PROJECT_VERSION"
echo "  目标库: $FOAM_USER_LIBBIN"
echo ""

# 进入编译目录
cd /workspace/src/thermophysicalModels/chemistryModel

# 步骤1: 清理
echo -e "${YELLOW}步骤1: 清理旧编译文件...${NC}"
wclean
rm -rf lnInclude
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

# 步骤2: 创建lnInclude
echo -e "${YELLOW}步骤2: 创建lnInclude目录...${NC}"
wmakeLnInclude .
echo -e "${GREEN}✓ lnInclude创建完成${NC}"
echo ""

# 步骤3: 编译
echo -e "${YELLOW}步骤3: 编译库文件...${NC}"
echo "正在编译 pyjac_dummy.c 和其他源文件..."
wmake libso 2>&1 | tee compile.log

# 检查编译是否成功
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✓ 编译成功!${NC}"
    echo ""
    
    # 步骤4: 验证符号
    echo -e "${YELLOW}步骤4: 验证eval_h符号...${NC}"
    
    if nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -q " T eval_h"; then
        echo -e "${GREEN}✓ eval_h符号已找到!${NC}"
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so | grep eval_h
    else
        echo -e "${RED}✗ 警告: eval_h符号未找到${NC}"
        echo "尝试查找相关符号..."
        nm $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so 2>/dev/null | grep -E "eval|pyjac" | head -10
    fi
    
    echo ""
    echo "================================================"
    echo -e "${GREEN}编译完成!${NC}"
    echo "================================================"
    echo ""
    echo "库文件位置:"
    echo "  $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so"
    echo ""
    echo "文件信息:"
    ls -lh $FOAM_USER_LIBBIN/libcemaPyjacChemistryModel.so
    echo ""
    echo "下一步:"
    echo "1. 在你的算例controlDict中添加:"
    echo '   libs ("libcemaPyjacChemistryModel.so");'
    echo "2. 运行reactingFoam"
    echo "================================================"
    
    # 检查编译日志中是否包含pyjac_dummy.c
    echo ""
    echo "编译日志检查:"
    if grep -q "pyjac_dummy.c" compile.log; then
        echo -e "${GREEN}✓ pyjac_dummy.c已被编译${NC}"
    else
        echo -e "${YELLOW}⚠ 编译日志中未发现pyjac_dummy.c${NC}"
        echo "  请检查compile.log文件"
    fi
    
else
    echo -e "${RED}✗ 编译失败!${NC}"
    echo ""
    echo "错误信息已保存在compile.log"
    echo ""
    echo "常见问题:"
    echo "1. OpenFOAM环境未正确设置"
    echo "2. 源文件路径错误"
    echo "3. 依赖库缺失"
    echo ""
    echo "请查看compile.log了解详细错误信息"
    exit 1
fi