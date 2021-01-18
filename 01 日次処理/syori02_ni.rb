#! /usr/local/rbenv/shims/ruby
# -*- mode:ruby; coding:utf-8 -*-
#
# テストSVから、ユーザーコードと施設コードを指定して、scodelistテーブルのdeadをFalse→Trueに更新する処理です
# 
# 《使い方》
#   1) テストSVの /home/sofinet に移動
#   2) ruby syori02_ni.rb を実行 (引数は「ユーザーコード,施設コード」の形式で入力して下さい)
#      例） syori02_ni.rb 1,3
#   3) -dまたは、-dispオプションをつけると、scodelistのdeadの状態を表示します
#      例)  syori02_ni.rb 1,3 -disp

require 'pg'
require 'yaml'

# ---------------------------------------------------------------------------------------------
# テストサーバーへの接続
# ---------------------------------------------------------------------------------------------
class DB_TesCon

    def initialize

        @has_option = {'d1' => '-disp', 'd2' => '-d', 't1' => '-test', 't2' => '-t'}
        @userid     = nil                     # ユーザーコード
        @fscode     = nil                     # 施設コード
        @arg_option = nil                     # オプション
        get_yaml
    end
	
    # ---------------------------------------------------------------------------------------------
    # scodelistテーブルを更新
    def update_scode(_tbl)

        # テスト/本番 テーブル名切り分け
        _tbl = case _tbl
            when :tst then "scodelist_test"
            when :hon then "scodelist"
        end

        begin
            # PostgreSQL(テスト)に接続
            connection = PG::connect(:host => @pghost, :user => @pguser, :password => @pgpasswd, :dbname => @pgdbname)
            
            # scodelistテーブルを検索
            _sql = "Select userid, fscode, dead From #{_tbl} Where userid = \'#{@userid}\' And fscode = \'#{@fscode}\' "
            _res = connection.exec(_sql)

            if _res.ntuples.zero?
                _msg = "scodelistに該当のデータが存在しません"
            else
                _dead = nil
                _res.each {|_rec| _dead = _rec['dead']}

                _argv1 = "#{@userid.to_i},#{@fscode.to_i}"
                _argv2 = _argv1.split(",").map(&:to_i)

                # オプション指定がない場合は更新する
                if @arg_option.nil?
                    if _dead.to_s == "t"
                        _msg = "scodelistでdead=Tになっているため、更新は行われません"
                    else
                        _sql = "Update #{_tbl} Set dead = true Where userid = \'#{@userid}\' And fscode = \'#{@fscode}\'"
                        connection.exec(_sql)

                        _msg = "#{_argv2}" + " scodelistのdeadをF→Tに更新しました"
                    end
                else
                    case @arg_option
                        when 'd'
                            _msg = "#{_argv2}" + " scodelistのdeadの状態は " + "#{_dead.to_s}" + " です"
                        when 't'
                            _msg = "#{_argv2}" + " テスト文言の表示だけです"
                    end
                end
            end

            unless _msg.nil?
                puts _msg 
                return :NG
            end

        return :OK
        rescue => ex
            print "***** " + self.class.name.to_s + "." + __method__.to_s + " *****\n"
            print(ex.class," -> ",ex.message," --> ",ex.backtrace)
            return :NG
        ensure
            connection.finish
        end
    end	
	
	# ---------------------------------------------------------------------------------------------
	# 引数入力の妥当性チェック
    def check_argv(_argv)

        if _argv.empty?
            _msg = "引数が設定されていません"
        else
            if _argv[0].to_s.slice(/^[0-9]+,[0-9]+$/).nil?
                _msg = "引数の型が正しくありません  「ユーザーコード,施設コード」で指定して下さい"
            end
            if _argv[1].to_s.empty?
            else
                if @has_option.value?(_argv[1].to_s)
                    @arg_option = @has_option.invert[_argv[1].to_s][0]  # オプションの種類
                else
                    _msg = "オプションの指定に誤りがあります"
                end
            end
        end

        if _msg.nil?
            @userid = _argv[0].to_s.split(",")[0]           # ユーザーコード
            @fscode = _argv[0].to_s.split(",")[1]           # 施設コード
            return :OK
        else
            puts _msg
            return :NG
        end
    end

	# ---------------------------------------------------------------------------------------------
	# YAMLファイルからパラメータを取得
    def get_yaml
        yml = YAML.load_file("./sofit_config.yml")
        hash = yml.fetch("databese_test")

        @pghost   = hash.fetch("host")
        @pguser   = hash.fetch("user")
        @pgpasswd = hash.fetch("passwd")
        @pgdbname = hash.fetch("dbname")
    end
end

# ============================================
# メイン処理
# ============================================
# テストサーバー側で実行
# PostgreSQL(テスト)に接続
udb = DB_TesCon.new

# 引数入力の妥当性チェック
exit(0) if udb.check_argv(ARGV) == :NG

# scodelistの更新(本番 :hon / テスト :tst)
udb.update_scode(:hon)
exit(0)