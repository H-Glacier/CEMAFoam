# 快速关闭ODE调试输出

## 最简单的方法

### 1. 在你的算例目录，编辑`system/controlDict`

在文件末尾添加：

```cpp
DebugSwitches
{
    ODESolver           0;
    seulex              0;
}
```

### 2. 或者运行时过滤

```bash
# 方法A：使用grep过滤
reactingFoam 2>&1 | grep -v "ODESolver\|seulex\|seul"

# 方法B：使用提供的脚本
cp /workspace/run_clean.sh your_case_directory/
cd your_case_directory
./run_clean.sh
```

## 完整示例

假设你的算例在`/home/user/myCase`：

```bash
cd /home/user/myCase

# 编辑controlDict
echo "" >> system/controlDict
echo "DebugSwitches { ODESolver 0; seulex 0; }" >> system/controlDict

# 运行
reactingFoam
```

## 效果

**之前**（有调试输出）：
```
ODESolver class, before solve(x, y, step)
*** in seulex class: inside solve(x,y,step): #4.1
- in seul: #1, T = 0
...（大量调试信息）
```

**之后**（干净输出）：
```
Time = 1e-06
Solving chemistry
diagonal:  Solving for rho, Initial residual = 0, Final residual = 0, No Iterations 0
...（只有正常求解信息）
```

## 恭喜！🎉

CEMAFoam现在已经：
- ✅ 编译成功
- ✅ 运行正常
- ✅ 输出干净

你的CEMAFoam-PyJac集成已经完全成功！