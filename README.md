# bioinfo

シングルセル(scanpy / anndata / pydeseq2)、RNA-seq、Hi-C 解析を一つの環境にまとめた
pixi 管理の Python 環境を、Docker イメージとして配布できるようにした構成です。

## 構成ファイル

| ファイル | 役割 |
|---|---|
| `pixi.toml` | 依存パッケージの定義(conda-forge / bioconda) |
| `pixi.lock` | 依存関係を固定するロックファイル(初回 `pixi install` 実行後に生成) |
| `Dockerfile` | pixi のマルチステージビルドで軽量な実行用イメージを作成 |
| `.dockerignore` | ビルドコンテキストから不要なファイルを除外 |
| `docker-compose.yml` | ローカルでの起動・データマウントを簡略化 |

## 使い方

### 1. (推奨)ローカルで pixi.lock を先に生成する

再現性を完全に固定するため、Docker ビルドの前に一度ローカルで pixi をインストールし、
ロックファイルを生成してリポジトリにコミットしておくことを推奨します。

```bash
# pixi本体のインストール(初回のみ)
curl -fsSL https://pixi.sh/install.sh | sh

# 依存関係を解決し pixi.lock を生成
pixi install
```

これを省略しても Dockerfile 側で自動的にインストール・解決されますが、
ビルドごとに依存関係の解決結果が変わる可能性があります。

### 2. Docker イメージのビルドと起動

```bash
docker build -t bioinfo-singlecell-hic-rnaseq .
docker run -it --rm -p 8888:8888 -v "$(pwd)/data:/app/data" bioinfo-singlecell-hic-rnaseq
```

または docker-compose を使う場合:

```bash
docker compose up --build
```

起動後、ブラウザで `http://localhost:8888` を開くと JupyterLab にアクセスできます
(トークン認証は開発用に無効化しています。共有環境で使う場合は `Dockerfile` の
`CMD` 行からトークン無効化オプションを外してください)。

### 3. バッチ処理として使う場合

JupyterLab を起動せず、スクリプトを直接実行することもできます。

```bash
docker run --rm -v "$(pwd):/app" bioinfo-singlecell-hic-rnaseq python my_analysis.py
docker run --rm -v "$(pwd):/app" bioinfo-singlecell-hic-rnaseq samtools sort input.bam -o sorted.bam
```

`entrypoint.sh` が pixi 環境をアクティベートしてからコマンドを実行するため、
`pixi run` を介さずに `scanpy` や `samtools` などをそのまま呼び出せます。

## 含まれている主なツール

- **シングルセル**: scanpy, anndata, pydeseq2, leidenalg, python-igraph
- **RNA-seq**: STAR, salmon, samtools, subread(featureCounts), fastp, FastQC, MultiQC
- **Hi-C**: cooler, cooltools, pairtools, HiCExplorer, bwa, bowtie2

## 補足事項

- **プラットフォーム**: `pixi.toml` は `linux-64` のみを対象にしています。Docker 上で動かす前提のためです。
  macOS 上で pixi 単体(Docker抜き)でも使いたい場合は、`platforms` に `osx-arm64` 等を
  追加してください(一部のバイオインフォマティクス系ツールは Apple Silicon 向けビルドが
  提供されていない場合があるため、その際は `osx-64` での利用を検討してください)。
- **イメージサイズ**: 上記の構成だけでもアライナー類を含むため数GB程度になります。
  scvi-tools のような PyTorch 依存のパッケージを追加するとさらに大きくなりますので、
  必要な解析に応じて `pixi.toml` の内容を絞ることをお勧めします。
- **HPCクラスタで Singularity / Apptainer を使う場合**: 同じ pixi.toml を流用し、
  Apptainer の定義ファイル(`.def`)でも同様のマルチステージ構成が可能です。
  必要であれば、その変換版もご用意できますので、お知らせください。
