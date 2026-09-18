# ollama-watch

Run an Ollama chat beside live Apple Silicon resource monitoring in one temporary tmux workspace.

`ollama-watch` opens three terminal panes:

```text
┌───────────────────────────────┬────────────────────┐
│                               │ macmon             │
│ ollama run MODEL              │ CPU / GPU / memory │
│                               ├────────────────────┤
│                               │ ollama ps          │
└───────────────────────────────┴────────────────────┘
```

The session cleans itself up when the Ollama chat exits. No daemon configuration is changed, no model is downloaded automatically, and no telemetry is added.

> A real terminal screenshot will be added in a future release.

## Requirements

- macOS on Apple Silicon
- [Ollama](https://ollama.com/)
- [tmux](https://github.com/tmux/tmux)
- [macmon](https://github.com/vladkens/macmon)

Install the command-line dependencies with Homebrew:

```sh
brew install ollama tmux macmon
```

Pull at least one model yourself. The default is Qwen 3.5 9B:

```sh
ollama pull qwen3.5:9b
```

## Install

```sh
git clone https://github.com/kisara174/ollama-watch.git
cd ollama-watch
./install.sh
```

The installer copies the launcher to `~/.local/bin/ollama-watch`. If that directory is not already on `PATH`, it adds one clearly marked block to `~/.zshrc`. It never installs dependencies or pulls models.

Open a new terminal after installation, or run `source ~/.zshrc` once.

## Usage

Start the default model:

```sh
ollama-watch
```

Start a specific installed model:

```sh
ollama-watch qwen3.5:9b
ollama-watch qwen3.5:14b
```

The model name must exactly match the first column of `ollama list`. Run `ollama-watch --help` for the command summary.

## tmux controls

tmux uses `Ctrl-b` as its prefix. Useful controls are:

- `Ctrl-b`, then an arrow key: move between panes.
- `Ctrl-b`, then `z`: zoom or restore the current pane.
- `Ctrl-b`, then `d`: detach while leaving the session running.

Run `tmux attach` to return to a detached session. When started from an existing tmux client, `ollama-watch` switches that client to the new session instead of nesting tmux.

## Cleanup behavior

Each invocation creates a uniquely named `ollama-watch-PID` session. Exiting the Ollama chat with `/bye`, `Ctrl-d`, or an interrupt ends only that session. If setup fails partway through, the launcher also removes only the session it created.

## Reading memory numbers

Apple Silicon uses Unified memory shared by the CPU, GPU, and other system components. macmon's memory and GPU readings therefore will not look like dedicated VRAM statistics from an NVIDIA system. `ollama ps` shows which models Ollama currently has loaded and the processor split selected by Ollama.

## Troubleshooting

### `Missing dependency`

Install the named tool with Homebrew, then retry. The launcher deliberately does not change your machine automatically.

### `Model is not installed`

Check the exact name with `ollama list`, or pull it explicitly:

```sh
ollama pull MODEL_NAME
```

### The command is not found after installation

Open a new terminal or run:

```sh
source ~/.zshrc
```

### A detached session is still running

List sessions with `tmux list-sessions` and reattach with `tmux attach -t SESSION_NAME`. Avoid killing unrelated tmux sessions.

## Uninstall

From the cloned repository, run:

```sh
./uninstall.sh
```

The uninstaller removes the installed launcher and only the marked `ollama-watch` block from `.zshrc`. It does not remove Ollama, tmux, macmon, models, or unrelated shell settings.

## 中文说明

`ollama-watch` 会在临时 tmux 会话中同时显示 Ollama 对话、macmon 的 CPU/GPU/统一内存状态，以及每两秒刷新的 `ollama ps`。

安装依赖与默认模型：

```sh
brew install ollama tmux macmon
ollama pull qwen3.5:9b
```

然后克隆本仓库并运行 `./install.sh`。使用 `ollama-watch` 启动默认 9B 模型，或用 `ollama-watch qwen3.5:14b` 指定其他已安装模型。退出 Ollama 后，当前监控会话会自动清理。

卸载请在仓库目录运行 `./uninstall.sh`；它只删除本工具和自己写入的 PATH 配置块。

## License

MIT. See [LICENSE](LICENSE).

