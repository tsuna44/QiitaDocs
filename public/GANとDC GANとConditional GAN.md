---
title: GANとDC GANとConditional GAN
tags:
  - DCGAN
  - GAN
  - ラビットチャレンジ
private: false
updated_at: '2021-08-21T17:59:27+09:00'
id: 9abc0a0d7d99cdef6aa5
organization_url_name: null
slide: false
ignorePublish: false
---
学習したことを忘れないように、メモっておこうかと。
# GAN
生成器(Genrerator)と識別器(Discriminator)を競わせて学習する生成＆識別モデル

わかりやすかったページ

https://blog.negativemind.com/2019/09/07/deep-convolutional-gan/

https://qiita.com/triwave33/items/1890ccc71fab6cbca87e

## Generator
入力：乱数 (noize)

## Discriminator
学習時の入力：真のデータ
識別時の入力：Generatorの生成データ

## 価値関数
価値関数𝑉に対し, 𝐷が最大化, 𝐺が最小化を行う。

勝利する確率を最大化したい：D は偽物を摘出するために勝利したい。
相手の勝利する確率を最小化したい：GはDを騙したい。

価値観数を V(D, G) とする。（Dが勝利する確率）

```math
\underset{G}{min} \, \underset{D}{max} V(D, G) \\
V(D,G) = \mathbb{E}_{x〜p_{data}(x)}[logD(x)] + \mathbb{E}_{z〜p_x(x)}[log(1-(G(z))]
```

これ、バイナリークロスエントロピーなんです。

### バイナリークロスエントロピー
閑話休題。
バイナリークロスエントロピーは、下記のような定義。

```math
L = - \sum ylog\widehat{y} + (1-y)log(1-\widehat{y})
```
y: 真値
$\widehat{y}$ : 予測値

#### 真データを扱う時
y=1, $\widehat{y} = D(x)$ なんです。
すると、価値関数は

```math
L = - log[D(x)]
```

#### 生成データを扱う時
y=0, $\widehat{y} = D(G(z))$ なんです。
すると、価値関数は

```math
L = - log[1-D(G(x))]
```

GAN の価値関数は、バイナリークロスエントロピーの真データを扱う時と、生成データを扱う時の2つを足し合わせたもの。

期待値は下記になる。

```math
期待値 = \sum xp(x)
```

価値関数をいい感じにするために、下記のステップで算出する。

1. Gを固定して価値関数が最大値になる D(x) を算出する。
1. 求められたD(x)を価値関数に代入して、Gが価値関数を最小化する条件を算出する。

まずは、Discriminator, Generator のパラメータを最適化する。

### パラメータの最適化
#### Discriminatorのパラメータ最適化
Discriminator のパラメータ $\theta_d$ をk回更新する。

Generator のパラメータ $\theta_g$ は固定する。

- 使用するサンプル
    真データと生成データを𝑚個ずつサンプル

- 更新式
    勾配上昇法(Gradient Ascent)で更新する。

```math
\frac{\partial}{\partial\theta_d} \frac{1}{m}[log[D(x)]] + log[1-D(G(z))]]
```

#### Generator のパラメータ最適化

Generator のパラメータ$\theta_g$を 1回更新する。

Discriminator のパラメータ $\theta_d$ は固定する。

- 使用するサンプル
    生成データを𝑚個ずつサンプル

- 更新式
    勾配降下法(Gradient Decent)で更新する。

```math
\frac{\partial}{\partial\theta_g} \frac{1}{m}[log[1-D(G(z))]]
```

Generatorが本物のようなデータを生成する状況は、下記のように生成したものと、真のデータが一致している場合。

```math
p_g = p_{data}
```

### 価値関数を最大化する D(x) の求め方
Generatorを固定する。

```math
\begin{eqnarray}
V(D,G) &=& \mathbb{E}_{x〜p_{data}(x)}[logD(x)] + \mathbb{E}_{z〜p_x(x)}[log(1-(G(z))]\\
&=& \int_x p_{data}(x)log(D(x))dx +\int_zp_z(z)log(1-D(G(z)))dz \\
&=& \int_x p_{data}(x)log(D(x)) + p_g(x)log(1-D(x))dx
\end{eqnarray}
```

ここで一旦、下記に置き換える。

```math
\begin{eqnarray}
y &=& D(x)\\
a &=& p_{data}(x)\\
b &=& p_g(x)
\end{eqnarray}
```

すると、下記式の極値を求める感じに簡略化できる。
おお！(@o@)

```math
alog(y) + blog(1-y)
```

yで微分すると、下記式になる。

```math
\frac{a}{y} + \frac{b}{1-y}(-1) = 0\\
y= \frac{a}{a+b}
```

先ほど置き換えた式を思い出して、戻すと

```math
D(x) = \frac{p_{data}(x)}{p_{data}(x) + p_g(x)}
```

になる。

### 価値関数はいつ、最小化するか求め方

先ほど求めた D(x)で V(D,G)を置き換える。

```math
\begin{eqnarray}
V &=& \mathbb{E}_{x〜p_{data}}log[\frac{p_{data}(x)}{p_{data}(x) + p_g(x)}] + \mathbb{E}_{z〜p_g}log[1-\frac{p_{data}(x)}{p_{data}(x) + p_g(x)}]\\
&=& \mathbb{E}_{x〜p_{data}}log[\frac{p_{data}(x)}{p_{data}(x) + p_g(x)}] + \mathbb{E}_{z〜p_g}log[\frac{p_{g}}{p_{data}(x) + p_g(x)}]\\
\end{eqnarray}
```

$p_{data}$と$p_g$ がどれだけ似ているかわかれば良い。
指標として、JSダイバージェンスがある。

JSダイバージェンスは非負で、分布が一致する時のみ 0 になる。

価値関数を変形する。

```math
\begin{eqnarray}
&=& \mathbb{E}_{x〜p_{data}}log[\frac{p_{data}(x)}{p_{data}(x) + p_g(x)}] + \mathbb{E}_{z〜p_g}log[\frac{p_{g}}{p_{data}(x) + p_g(x)}]\\
&=& \mathbb{E}_{x〜p_{data}}log[\frac{2p_{data}(x)}{p_{data}(x) + p_g(x)}] + \mathbb{E}_{z〜p_g}log[\frac{2p_{g}}{p_{data}(x) + p_g(x)}] -2log2\\
&=& 2JS(p_{data}||p_g) - 2log2
\end{eqnarray}
```

$p_{data} = p_g$ の時に最小値になる。
つまり、JS(p_{data}||p_g) = 0 の時。

#DCGAN
GAN の生成品質を向上させた。

わかりやすかったページ

https://qiita.com/triwave33/items/35b4adc9f5b41c5e8141

GANとの違いと、同じことは下記の通り。

## Generator
- Pooling層ではなく、転置畳み込み層を使う。
    乱数を画像にアップサンプリングする。

- 使用する活性化関数は、最終層は tanh、その他はReLU関数。

## Discriminator
- Pooling層ではなく、畳み込み層を使う。

    画像から特徴量を抽出して、最終層をsigmoid関数で活性化する。

- 使用する活性化関数は、Leaky ReLU関数

## 変わらないこと
- 中間層に前結合層を使わない。
- バッチノーマライゼーションを使う。

#Conditional GAN
- Generator にもラベルを与える。
- 画像や説明文も扱える。
- 条件ラベルの入力に用いる方法の1つにEmbedding層を使うことが考えらえる。
- Discriminator　は入力サンプルが本物でもラベルと一致しなければ拒絶する。
- Generator に U-Net を用いる。








