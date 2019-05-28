#! /usr/local/rbenv/shims/ruby
# -*- mode:ruby; coding:utf-8 -*-
#
# テストSVでcheckstateテーブルのresultを全データに対し0に更新する処理です。
# 《使い方》
#   1) テストSVの /home/sofinet に移動
#   2) ruby syori01_ni.rb を実行 (引数の指定はなし)
# 

require 'pg'
require 'yaml'

# ---------------------------------------------------------------------------------------------
# テストサーバーへの接続
# ---------------------------------------------------------------------------------------------
class DB_TesCon

    def initialize
        get_yaml
	end
		
	# ---------------------------------------------------------------------------------------------
	# checkstateテーブルを更新
	def update_check(_tbl)
		
		# テスト/本番 テーブル名切り分け
		_tbl = case _tbl
			when :tst then "checkstate_test"
			when :hon then "checkstate"
		end

        _cntbe = 0
        _cntaf = 0

        begin
			# PostgreSQL(テスト)に接続
		    connection = PG::connect(:host => @pghost, :user => @pguser, :password => @pgpasswd, :dbname => @pgdbname)
            
            # checkstateテーブルを検索
            _sql = "Select userid, result From #{_tbl} Where Not (result = 0) Order by userid"
            _res = connection.exec(_sql)

            if _res.ntuples.zero?
                _msg1 = "checkstateにあるデータは、全てresult=0です"
                _msg2 = nil
            else
                _ary = []
                _res.each { |_rec| _ary << _rec['userid'].to_i }
                   
                # checkstateテーブルの更新
                _sql = "Update #{_tbl} Set result = 0 Where Not (result = 0)"
                connection.exec(_sql) 

                _msg1 = "checkstateのresultを0に更新しました  #{_ary.size} 件"
                _msg2 = "更新したユーザーは #{_ary} です"
            end

            # 処理結果を表示
            puts _msg1
            puts _msg2 unless _msg2.nil?

		rescue => ex
			print "***** " + self.class.name.to_s + "." + __method__.to_s + " *****\n"
            print(ex.class," -> ",ex.message," --> ",ex.backtrace)
        ensure
			connection.finish
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

# checkstateテーブルの更新(本番 :hon / テスト :tst)
udb.update_check(:hon)

exit (0)
