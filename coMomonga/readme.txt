coMomongaのディスクイメージを作っちゃうスクリプト

エラーが起きようと、止まらずに突き進みます。
ご使用の際はご注意ください。

必要な物

1.ruby
2.rpmファイルを置くために/tmpに1G以上の空き領域
  (スクリプトの修正で別のディレクトリへの変更もできます)


使い方(coLinux編)

1.インストール先のイメージファイルをddするか、
  http://dist.momonga-linux.org/pub/momonga/1/i586/colinux/のext3_XXX.img.bz2辺りから持ってくる
2.coLinuxの設定ファイルに以下のような行を追加して、インストール先イメージファイルを"/dev/cobd2"に割り振る
   <block_device index="2" path="\DosDevices\c:\coLinux\coMomo-new.img" enabled="true" />

3./tmpに1G程度の空きが有る事を確認する
4.momo.shを実行。エラーが出ずにスクリプトが終了したら終了です。


使い方(普通のLinux編)

1.dd等を使用してインストール先イメージファイルを作成する。
2."momo.sh"の以下の部分を修正する

  a.インストール先をディスクイメージにする
    momo.shの5行目辺り

        (例)
        TARGETDISK="/dev/cobd2"  -> TARGETDISK="/home/meke/coMomo/momo-dev.img"
       
  b.マウントのオプションを変更する。
    momo.shの70行目辺り

        # image file
        # mount -o loop -t ext3 $TARGETDISK $TARGETDIR
        
        # block device
        mount -t ext3 $TARGETDISK $TARGETDIR

	これを

        # image file
        mount -o loop -t ext3 $TARGETDISK $TARGETDIR
        
        # block device
        # mount -t ext3 $TARGETDISK $TARGETDIR


3./tmpに1G程度の空きが有る事を確認する
4.momo.shを実行。エラーが出ずにスクリプトが終了したら終了です。

