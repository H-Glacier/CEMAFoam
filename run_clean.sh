#!/bin/bash
# 运行CEMAFoam并过滤调试输出

echo "================================================"
echo "   CEMAFoam运行脚本（无调试输出）"
echo "================================================"
echo ""

# 检查是否在算例目录
if [ ! -f "system/controlDict" ]; then
    echo "错误：请在OpenFOAM算例目录中运行此脚本"
    echo "当前目录：$(pwd)"
    exit 1
fi

# 备份controlDict
if [ ! -f "system/controlDict.orig" ]; then
    cp system/controlDict system/controlDict.orig
    echo "已备份controlDict到controlDict.orig"
fi

# 添加调试开关到controlDict（如果还没有）
if ! grep -q "DebugSwitches" system/controlDict; then
    echo "" >> system/controlDict
    echo "// 关闭ODE求解器调试输出" >> system/controlDict
    echo "DebugSwitches" >> system/controlDict
    echo "{" >> system/controlDict
    echo "    ODESolver           0;" >> system/controlDict
    echo "    seulex              0;" >> system/controlDict
    echo "    chemistryModel      0;" >> system/controlDict
    echo "}" >> system/controlDict
    echo "" >> system/controlDict
    echo "InfoSwitches" >> system/controlDict
    echo "{" >> system/controlDict
    echo "    ODESolver           0;" >> system/controlDict
    echo "    seulex              0;" >> system/controlDict
    echo "}" >> system/controlDict
    echo "已添加调试开关到controlDict"
fi

# 运行选项
echo ""
echo "选择运行方式："
echo "1) 正常运行（推荐）"
echo "2) 过滤输出运行"
echo "3) 并行运行"
read -p "请选择 [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "正在运行reactingFoam..."
        echo "======================================"
        reactingFoam | tee log.reactingFoam
        ;;
    2)
        echo ""
        echo "正在运行reactingFoam（过滤输出）..."
        echo "======================================"
        reactingFoam 2>&1 | grep -v -E "(ODESolver class|in seulex|in seul:|#[0-9]\.|#[0-9]," | tee log.reactingFoam
        ;;
    3)
        read -p "输入处理器数量: " nProcs
        echo ""
        echo "分解网格..."
        decomposePar
        echo ""
        echo "并行运行reactingFoam（${nProcs}个处理器）..."
        echo "======================================"
        mpirun -np $nProcs reactingFoam -parallel | tee log.reactingFoam
        echo ""
        echo "重构结果..."
        reconstructPar
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "运行完成！"
echo "日志文件：log.reactingFoam"
echo ""
echo "提示："
echo "- 查看日志：tail -f log.reactingFoam"
echo "- 恢复原始controlDict：cp system/controlDict.orig system/controlDict"
echo "======================================"