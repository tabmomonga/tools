#!/usr/bin/php-cli
<?php
/*
 * --------------------------------------------------------------------------------
 * cleanupsource.php
 * 	Copyright    : Copyright (C) 2003 Shigeyuki Yamashita <shige@cty-net.ne.jp>
 *  Time-Stamp   : 2003-08-12
 *  License      : GPL2
 * --------------------------------------------------------------------
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2 as published by the Free Software Foundation.
 * --------------------------------------------------------------------
 *
 * kazさんが rubyで書かれた cleanupsource を php で書いてみた
 * (実は cleanupsource の使い方が良く解らなかったので自分が使えるように……)
 *
 * [概要]
 *
 *  現在 SRPMS にある rpm のビルドに必要としていないソースをリストアップ & 削除しま
 * す．OmoiKondaraで長年ビルドを繰り返していると，現状のspecでは使っていない古いソー
 * スが SOURCESディレクトリに残存しますが，それら必要無いファイルを SRPMの情報を基に
 * リストアップし削除します．
 *
 * kazさんが書かれた cleanupsource が同じ動作をするのですが，私は ruby が解らず，どう
 * 引数を指定していいのか解らなかったので，自分が使いやすい様に php で同じような動作
 * をするスクリプトを作成しました．
 *
 * Momonga Projectは Rubyマスターが多いので php のスクリプトは相手にもされない(or 邪魔)
 * と思われるかも知れないですが……．
 *
 *
 * [動作]
 *
 *  1. SRPMSにある *.(nosrc|src).rpm に rpm -qpl を発行しソースファイルをリストする．
 *
 *  2. 同じく同ファイルを rpm2cpio と cpio で 含まれているソースファイルをリストする．
 *
 *  3. それらリストを基に必要としていないファイルをリストアップし，削除します．
 *
 * [以下特徴!?]
 *
 *  - ファイルリストのテンポラリファイルを書き出さない
 *
 *  - 冗長でウザイ
 *
 *  - Rubyマスターが多い Momonga Project では php で書いても相手にしてもらえない
 *
 *  - LANG=ja_JP.EUC-JP な環境じゃないとメッセージが化ける
 *
 *  - php-cliパッケージがインストールされてないと使えない
 *
 *  - エラー処理が雑スギ
 *
 * --------------------------------------------------------------------------------
 */

/*
 * ===== 検証ディレクトリ取得 =====
 */
$srpmsdir = "";
$srcdir   = "";

/* -----  / (ルート) からの絶対パスを要求 ----- */
$srpmsdir_regex = '^/.+/SRPMS$';
$srcdir_regex = '^/.+/SOURCES$';

if ($argv[1] != "") {
	$argv[1] = trim($argv[1]);
	if(preg_match("'--?(help|h|\?)'",$argv[1])) {
		// ヘルプ ミー らしい…
		fwrite(STDERR,"検証する SRPMS ディレクトリを / からの絶対パスで指定してください．\n");
		fwrite(STDERR,"Usage: {$argv[0]} <SRPMS directry>\n");
		exit();
	}
	else {
		$srpmsdir = preg_replace("'/$'","",$argv[1]);
		// ディレクトリ末尾の文字列は SRPMS で終っている筈
		if (!preg_match("'{$srpmsdir_regex}'",$srpmsdir)) {
			fwrite(STDERR,"入力が正しくありません．\n");
			list($srpmsdir,$srcdir) = get_path();
		}
		else {
			// で，あるなら，SOURCES ディレクトリは 同階層の SOURCES だろう
			$srcdir = preg_replace("'SRPMS$'","SOURCES",$srpmsdir);
		}
		// 一応確認の為 聞いてみる
		fwrite(STDERR,"SRPMS   → $srpmsdir\n");
		fwrite(STDERR,"SOURCES → $srcdir\n");
		fwrite(STDERR,"検証するディレクトリは上記で宜しいですか? [Y/n] : ");
		$dir_ok = "";
		$dir_ok = trim(fgets(STDIN,4));
		if(!preg_match("'^(y|yes)$'i",$dir_ok)) {
			// ちゃうらしいので検証ディレクトリを両方聞いてみる
			list($srpmsdir,$srcdir) = get_path();
		}
		else {
			fwrite(STDERR,"これらディレクトリ内を検証します．\n");
		}
	}
}
else {
	// 引数なしで呼ばれちゃったので検証ディレクトリを両方聞いとく
	list($srpmsdir,$srcdir) = get_path();
}

/*
 * ===== SRPM からリストを得る =====
 */
$src_list = array();
chdir($srpmsdir);
$d = false;
$d = dir($srpmsdir);

if($d !== false) {
	while(false !== ($srpm = $d->read())) {
		$cpio_list = array();
		$qpl_list = array();
		if (preg_match("|^.*.rpm$|",$srpm)) {
			$qpl_list = preg_split("'\n+'", `rpm -qpl $srpm`);
			$cpio_list = preg_split("'\n+'", `rpm2cpio $srpm | cpio --list 2>/dev/null`);
			foreach ($qpl_list as $src) {
			// rpm -qpl でリストされるが rpm ファイルに含まれてないソースを src_listへ
				if(!in_array($src, $cpio_list)) {
					array_push($src_list,$src);
				}
			}
		}
	}
	$d->close();
	unset($d);
}
else {
	// うわーん，読めないよー
	fwrite(STDERR,"{$srpmsdir} を読めません．\n");
	exit();
}

/*
 * ===== SOURCESディレクトリからファイルのリストを得る  =====
 */
chdir($srcdir);
$d = false;
$d = dir($srcdir);

if ($d !== false) {
	$src_files = array();
	while(false !== ($file = $d->read())) {
		$src_file = trim($file);
		//  . とか .. とかを除く
		if (!preg_match("'^(?:\.|\.\.)$'",$src_file)) {
			array_push($src_files,$src_file);
		}
	}
	$d->close();
	unset($d);
}
else {
	// うわーん，読めないよー
	fwrite(STDERR,"{$srcdir} を読めません．\n");
	exit();
}

/*
 * ===== 上で得たリストから余剰ソースファイルを調べる =====
 */
$surplus_list = array();
foreach($src_files as $src_file) {
	if (!in_array($src_file, $src_list)) { // in_array で力業…
		array_push($surplus_list, $src_file);
	}
}

if (count($surplus_list) == 0) {
	fwrite(STDERR,"削除すべき余剰ソースファイルはありません．\n\nたぶん……．\n");
	exit();
}
else {
	// 調べた結果を $HOME/source_surpluses へ書き残す
	$surpluses = join("\n",$surplus_list);
	$surplus_list_file = $_ENV['HOME'] . '/source_surpluses';
	$f = fopen($surplus_list_file, "w");
	if ($f == false) {
		// 自分の $HOME へファイルが書き出せない事はあまり無いと思うが…
		fwrite(STDERR, "余剰ソースのリストを書き出せません．\n");
		// 何を削除したか痕跡を残せない(削除したリストを残せずでは怖い)ので exit します．
		exit();
	}
	else {
		fwrite($f,$surpluses . "\n");
		fwrite(STDERR, "余剰ソースのリストを $surplus_list_file へ書き出しました．\n");
		// 削除するかどうか聞いてみる (「勝手に削除するなゴルァ」対策)
		fwrite(STDERR, $surpluses . "\n\nこれらファイルを削除しますか? [y/N] : ");
		$del_ok = "";
		$del_ok = fgets(STDIN,4);
		if (preg_match("'^(y|yes)$'i",$del_ok)) {
			foreach($surplus_list as $surplus) {
				if (unlink($surplus)) { // unlink成功なら
					// いちいち報告(かなりウザイ?)
					fwrite(STDERR, $surplus . " を削除しました．\n");
				}
				else { // 何らかの理由でunlinkできない
					fwrite(STDERR, $surplus . " を削除できません．\n");
				}
			}
		}
		else { // 勝手に削除はイヤーンらしい……
			fwrite(STDERR,"削除せず終了します．\n");
		}
	}
}

exit(); // 終了


/*
 * ----------------------------------------------------------------------
 * 検証する SRPMS，SOURCESの パスを入力してもらう
 * ----------------------------------------------------------------------
 */

function get_path() {
	global $srpmsdir_regex,$srcdir_regex;
	fwrite(STDERR,"検証する SRPMSディレクトリを / からの絶対パスで指定して下さい．\n");
	$srpmsdir = get_path_input($srpmsdir_regex);
	fwrite(STDERR,"検証する SOURCESディレクトリを / からの絶対パスで指定して下さい．\n");
	$srcdir = get_path_input($srcdir_regex);
	return array($srpmsdir,$srcdir);
}

function get_path_input($regex) {
	$directory = trim(fgets(STDIN,128));
	$directory = preg_replace("'/$'","",$directory);
	if (preg_match("'{$regex}'",$directory)) {
		return $directory;
	}
	else {
		fwrite(STDERR,"入力が正しくありません．もう一度入力して下さい．\n");
		get_path_input($regex);
	}
}


/*
 *  end of script
 */
?>