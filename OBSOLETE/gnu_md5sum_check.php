#!/usr/bin/php-cli
<?php
/*
 * --------------------------------------------------------------------------------
 *  gnu_md5sum_check.php
 *
 *  Copyright : Copyright (C) 2003 Shigeyuki
 *  Yamashita <shige@cty-net.ne.jp>
 *  Time-Stamp : 2003-08-12
 *  License : GPL2
 *
 *  --------------------------------------------------------------------
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  version 2 as published by the Free Software Foundation.
 *  --------------------------------------------------------------------
 *
 *
 * [概要]
 *
 *  gnu ftpサーバで公開されている安全確認リストとローカルに落してある
 *  ファイルの md5sum値の検証を行なう．
 *  see. http://ftp.gnu.org/MISSING-FILES.README
 *       http://www.cert.org/advisories/CA-2003-21.html
 *
 *
 * [動作]
 *
 *  1. 指定された SOURCESディレクトリのファイルをリストアップ．
 *
 *  2. 配布されているファイルに対するmd5 checksumの安全確認リストを読
 *     み込む．
 *
 *     安全確認リスト → ftp://ftp.gnu.org/before-2003-08-01.md5sums.asc
 *                       ftp://alpha.gnu.org/before-2003-08-01.md5sums.asc
 *
 *  3. ローカルのファイル名が安全確認リストにあれば，そのmd5sumとロー
 *     カルにあるソースのmd5sumを照合
 *
 *  4. 検証結果を $HOME/gnu_ftp_md5sum_check_result に書き出す．
 *
 * --------------------------------------------------------------------------------
 */

/*
 * ===== 検証ディレクトリ取得 =====
 */

function print_usage() {
	$me = basename($_SERVER["SCRIPT_NAME"]);
	$msg = <<<MSG
検証する SOURCES ディレクトリと安全確認リストのパス(or URL)を指定して下さい．

Usage:
	{$me} <SOURCES directry> <md5sums.ascのpath or URL>

[例]
\$ {$me} /hoge/PKGS/SOURCES ftp://ftp.gnu.org/before-2003-08-01.md5sums.asc


MSG;

	fwrite(STDERR,$msg);
}

/*
 * md5sums.asc を読み込んで ファイル名をキーとした filename => md5sum
 * な連想配列を生成
 */
function get_md5sums($filepath) {
	$tmpdata = array();
	$tmpdata = file($filepath);
	if(count($tmpdata) == 0) {
		fwrite(STDERR,"md5sumのリストを作成できません");
		exit();
	}
	$md5sums = array();
	$begin_msg = '-----BEGIN PGP SIGNED MESSAGE-----';
	$begin_pgp_sign = '-----BEGIN PGP SIGNATURE-----';

	foreach($tmpdata as $line) {
		if(preg_match("'^{$begin_pgp_sign}$'",$line)) {
			break;
		}
		else if(preg_match("'^(?:{$begin_msg}|Hash:.*|\s)$'",$line)) {
			continue;
		}
		else {
			$md5sum = "";
			$ftppath = "";
			$comment = "";
			$filename = "";
			// 空白 or tab区切りかと思われるので空白文字で行を3分割
			// でも $commentは結局は利用しない
			list($md5sum,$ftppath,$comment) = preg_split("'\s+'",$line,3,PREG_SPLIT_NO_EMPTY);
			// ファイル名をキーにして連想配列に
			$filename = basename($ftppath);
			// fwrite(STDERR,"{$filename} : {$md5sum}\n"); // debug用
			$md5sums["{$filename}"] = $md5sum;
		}
	}
	return $md5sums;
}

/*
 *  SOURCESディレクトリのソースファイルをリストアップする
 */
function get_srcfiles($srcdir) {
	chdir($srcdir);
	$d = false;
	$d = dir($srcdir);

	if ($d !== false) {
		$srcfiles = array();
		while(false !== ($file = $d->read())) {
			$srcfile = trim($file);
			//  . とか .. とかを除く
			if (!preg_match("'^(?:\.|\.\.)$'",$srcfile)) {
				array_push($srcfiles,$srcfile);
			}
		}
		$d->close();
		unset($d);
		natsort($srcfiles);
		return $srcfiles;
	}
	else {
		// うわーん，読めないよー
		fwrite(STDERR,"{$srcdir} を読めません．\n");
		exit();
	}
}


// main
if (($argc < 2) || preg_match("'--?(help|h|\?)'",$argv[1])) {
	print_usage();
	exit();
}
else {
	$srcdir = preg_replace("'/$'","",$argv[1]);
	$md5sum_file = trim($argv[2]);
	if(!is_dir($srcdir)) {
		fwrite(STDERR,"{$srcdir}はディレクトリではないか，存在しません．");
		exit();
	}
	$srcfiles = array();
	$md5sums = array();
	$srcfiles = get_srcfiles($srcdir);
	$md5sums = get_md5sums($md5sum_file);
	$danger_files = array();
	$unverifying  = array();
	$verifying    = array();
	$result = "";
	$result_file = $_ENV["HOME"] . '/gnu_ftp_md5sum_check_result';
	foreach($srcfiles as $srcfile) {
		if (!array_key_exists($srcfile,$md5sums)) {
			array_push($unverifying,"{$srcdir}/{$srcfile}");
		}
		else {
			$src_md5sum = "";
			$src_md5sum = md5_file($srcfile);
			$gnu_md5sum = "";
			$gnu_md5sum = $md5sums["{$srcfile}"];
			// debug start
			// fwrite(STDERR,"{$srcfile} を検証\n");
			// fwrite(STDERR,"ローカル {$src_md5sum} <=> リスト {$gnu_md5sum}\n\n");
			// debug end

			if (strcmp($src_md5sum,$gnu_md5sum) == 0) {
				array_push($verifying,"{$srcdir}/{$srcfile}");
			}
			else {
				array_push($danger_files,"{$srcdir}/{$srcfile}");
			}
		}
	}
	$sep = "#---------------------------------------------------------------------\n";
	$result .= $sep;
	$result .= "# {$md5sum_file}\n";
	$result .= "# のリストを基に，\n";
	$result .= "# {$srcdir}\n";
	$result .= "# にあるソースの md5sum検証を行ないました．\n";
	$result .= $sep . "\n\n" . $sep;
	$result .= "# [Safety] リストされていてmd5sumが一致するもの．\n";
	$result .= $sep;
	$result .= join("\n",$verifying) . "\n\n";
	$result .= $sep;
	$result .= "# [Danger?] リストの md5sum と一致しないもの．\n";
	$result .= $sep;
	$result .= join("\n",$danger_files) . "\n\n";
	$result .= $sep;
	$result .= "# [unverifying]\n";
	$result .= "# リストされていないもの or GNU のソースではないもの\n";
	$result .= $sep;
	$result .= join("\n",$unverifying) . "\n\n";
	// 調べた結果を $HOME/gnu_ftp_md5sum_check_result へ書き出す．
	$fp = fopen($result_file,"w");
	if ($fp == false) {
		// 自分の $HOME へファイルが書き出せない事はあまり無いと思うが…
		fwrite(STDERR, "検証結果を書き出せません．\n");
	}
	else {
		if (fwrite($fp,$result)) {
			fwrite(STDOUT,$result . "\n\n");
			fwrite(STDERR, "検証結果を {$result_file} へ書き出しました．\n");
		}
		else {
			fwrite(STDERR, "検証結果を書き出せません．\n");
		}
	}
	exit();
}

/*
 *  end of script
 */
?>