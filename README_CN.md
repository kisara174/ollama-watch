# ollama-watch

[English](README.md) | [简体中文](README_CN.md)

在一个临时 tmux 工作区中运行 Ollama 对话，并实时查看 Apple Silicon 的资源占用情况。

`ollama-watch` 会打开三个终端窗格：

```text
┌───────────────────────────────┬────────────────────┐
│                               │ macmon             │
│ ollama run MODEL              │ CPU / GPU / 内存   │
│                               ├────────────────────┤
│                               │ ollama ps          │
└───────────────────────────────┴────────────────────┘
```

退出 Ollama 对话后，临时会话会自动清理。本工具不会修改 Ollama 的守护进程配置，不会自动下载模型，也不包含遥测功能。

> 真实终端截图将在后续版本中补充。

## 环境要求

- Apple Silicon Mac
- [Ollama](https://ollama.com/)
- [tmux](https://github.com/tmux/tmux)
- [macmon](https://github.com/vladkens/macmon)

使用 Homebrew 安装命令行依赖：

```sh
brew install ollama tmux macmon
```

请自行下载至少一个模型。默认模型是 Qwen 3.5 9B：

```sh
ollama pull qwen3.5:9b
```

## 安装

```sh
git clone https://github.com/kisara174/ollama-watch.git
cd ollama-watch
./install.sh
```

安装脚本会将启动器复制到 `~/.local/bin/ollama-watch`。如果该目录尚未加入 `PATH`，脚本会在 `~/.zshrc` 中添加一个带有明确起止标记的配置块。安装脚本不会安装依赖，也不会下载模型。

安装后请打开一个新的终端，或者执行一次：

```sh
source ~/.zshrc
```

## 使用方法

启动默认模型：

```sh
ollama-watch
```

启动指定的已安装模型：

```sh
ollama-watch qwen3.5:9b
ollama-watch deepseek-r1:14b
```

模型名称必须与 `ollama list` 第一列中的名称完全一致。运行 `ollama-watch --help` 可以查看命令帮助。

## tmux 操作

tmux 的默认前缀键是 `Ctrl-b`，常用操作如下：

- 按 `Ctrl-b`，再按方向键：在窗格之间移动。
- 按 `Ctrl-b`，再按 `z`：放大或还原当前窗格。
- 按 `Ctrl-b`，再按 `d`：从会话分离，但保持会话运行。

运行 `tmux attach` 可以重新进入已分离的会话。如果从现有 tmux 客户端中启动，`ollama-watch` 会切换到新会话，而不会嵌套启动第二层 tmux。

## 自动清理机制

每次运行都会创建一个名称唯一的 `ollama-watch-PID` 会话。使用 `/bye`、`Ctrl-d` 或中断操作退出 Ollama 后，只会结束本次运行创建的会话。如果初始化中途失败，启动器同样只会清理自己创建的会话。

## 理解内存数据

Apple Silicon 使用由 CPU、GPU 和其他系统组件共享的统一内存。因此，macmon 显示的内存与 GPU 数据不会像 NVIDIA 设备的独立显存统计那样呈现。`ollama ps` 会显示 Ollama 当前加载的模型，以及 Ollama 选择的处理器分配情况。

GPU 利用率接近 100% 通常表示模型正在充分使用 GPU，并不代表只剩很少显存。判断能否运行更大的模型时，应重点观察统一内存压力和 Swap 使用量。

## 故障排查

### 出现 `Missing dependency`

请使用 Homebrew 安装提示中所列的工具，然后重新运行。启动器不会自动修改你的电脑。

### 出现 `Model is not installed`

使用 `ollama list` 检查准确的模型名称，或者自行下载：

```sh
ollama pull MODEL_NAME
```

### 安装后找不到命令

打开一个新的终端，或者运行：

```sh
source ~/.zshrc
```

### 已分离的会话仍在运行

使用 `tmux list-sessions` 查看会话，再使用 `tmux attach -t SESSION_NAME` 重新进入。不要结束与 `ollama-watch` 无关的 tmux 会话。

## 卸载

在克隆的仓库目录中运行：

```sh
./uninstall.sh
```

卸载脚本只会删除已安装的启动器，以及 `.zshrc` 中由 `ollama-watch` 管理的标记配置块。它不会删除 Ollama、tmux、macmon、模型文件或其他 Shell 配置。

## 许可证

本项目采用 MIT 许可证，详情见 [LICENSE](LICENSE)。
