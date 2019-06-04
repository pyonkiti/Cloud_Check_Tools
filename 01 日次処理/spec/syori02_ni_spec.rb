#
# syori02_ni.rbのcheck_argvメソッドの単体テスト
#

require_relative '../syori02_ni.rb'

describe DB_TesCon do

	# クラスを定義
	let(:db_tescon) { DB_TesCon.new("192.168.19.11", "postgres", "sofinet", "sw_cloud_users") }
	
	context "check_argv" do

		it "OK パターン" do
			expect(db_tescon.check_argv(["2,101"])).to  eq :OK
			expect(db_tescon.check_argv(["2,102"])).to  eq :OK
		end

		it "引数が設定されていません" do
			expect(db_tescon.check_argv([])).to         eq :NG
		end

		it "引数の型が正しくありません" do
			expect(db_tescon.check_argv([","])).to      eq :NG
			expect(db_tescon.check_argv([",,"])).to     eq :NG
			expect(db_tescon.check_argv([",10"])).to    eq :NG
			expect(db_tescon.check_argv(["100"])).to    eq :NG
			expect(db_tescon.check_argv(["100,"])).to   eq :NG
			expect(db_tescon.check_argv(["1a,222"])).to eq :NG
			expect(db_tescon.check_argv(["1,4a"])).to   eq :NG
			expect(db_tescon.check_argv(["1,4,5"])).to  eq :NG
		end
	end
end
