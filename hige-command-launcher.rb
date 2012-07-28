# -*- coding: utf-8 -*-
#############################################################
#
#  HIGE-COMMAND-LAUNCHER  2012.06
#
#入力欄にキーワードを入力しリターンキーを押すと、対応するコマンドが発動。自身は終了する。
#ブラウザでの検索機能付き。この場合はキーワードと検索語の間に空白を１つ入れる。
############################################################

require 'gtk2'
require 'yaml'
DIR = File.dirname(__FILE__)
ICONDIR = "#{DIR}/icons"
$list = YAML.load_file("#{DIR}/commandlist.yml")

def search(url, word)
  case url
  when "g"
    exec("firefox https://www.google.co.jp/#q=#{word}")
  when "m"
    exec("firefox https://maps.google.com/maps?q=#{word}")
  when "w"
    exec("firefox http://ejje.weblio.jp/content/#{word}")
  when "a"
    exec("firefox http://eow.alc.co.jp/search?q=#{word}")
  end
end

def narrow_candidate(keyword)
  $list.select { |k, v| /#{keyword}/ =~ k }
end

def invoke_app(keyword)
  $list.each do |k, v|
    if k == keyword
      exec(v[2])
    end
  end
end

$keyword = 0; $pixbuf = 1; $application = 2; $command  = 3    # columnの並び順
def setup_tree_view(treeview)
# create 'keyword' column
  renderer = Gtk::CellRendererText.new
  column = Gtk::TreeViewColumn.new("Keyword", renderer, "text" => $keyword)
  treeview.append_column(column)

# create 'application' column with two renderers
  column = Gtk::TreeViewColumn.new
  column.title = "Application"

  renderer = Gtk::CellRendererPixbuf.new
  column.pack_start(renderer, false)
  column.add_attribute(renderer, 'pixbuf', $pixbuf)

  renderer = Gtk::CellRendererText.new
  column.pack_start(renderer, true)
  column.add_attribute(renderer, "text", $application)
  treeview.append_column(column)

# create 'command' column
  renderer = Gtk::CellRendererText.new
  column = Gtk::TreeViewColumn.new("Command", renderer, "text" => $command)
  treeview.append_column(column)
end

def setup_list(list, store)
store.clear
  list.each do |k, v|
    iter = store.append
    store.set_value(iter, $keyword, k )
    store.set_value(iter, $pixbuf, Gdk::Pixbuf.new("#{ICONDIR}/#{v[1]}", 32, 32))
    store.set_value(iter, $application, v[0])
    store.set_value(iter, $command,  v[2])
  end
end

#######################
###各コンテナを作る
######################
#一番外枠のコンテナ
window = Gtk::Window.new
window.title = "hige-command-launcher"
window.border_width = 10
window.signal_connect('delete_event') { Gtk.main_quit }
#window.set_size_request(700, 500)

#キーワード入力エリアのコンテナ
entryarea = Gtk::Entry.new
entryarea.visibility = true
entryarea.signal_connect('activate'){
  text = entryarea.text
  case text
  when ""
  when /^(.)\s(.+)/ ; search($1, $2)
  else invoke_app(entryarea.text)
  end
  Gtk.main_quit
}

# completion
completion = Gtk::EntryCompletion.new
entryarea.set_completion(completion)
liststore = Gtk::ListStore.new(String, Gdk::Pixbuf, String, String)
completion.set_model(liststore)

liststore.set_sort_column_id(0, Gtk::SORT_ASCENDING)

completion.set_text_column(0)
completion.set_inline_completion(true)
completion.popup_completion = false
#文の途中でもマッチさせてpop-upに表示させる。がpop-upの機能を止めているのでここでは使用しない
# completion.set_match_func do |completion, key, iter|
# model = completion.model
# text = model.get_value(iter, 0)
#   /#{key}/ =~ text
# end

entryarea.signal_connect('changed'){
  setup_list( $list.find_all{ |k, v| /#{entryarea.text}/ =~ k}, liststore)
}

# listを一覧表示させるコンテナ
setup_list($list, liststore)
treeview = Gtk::TreeView.new
setup_tree_view(treeview)
treeview.model = liststore
treeview.signal_connect('row-activated') do |s, path, column|
  selection = treeview.selection
  model = s.model
  invoke_app(model.get_value(selection.selected, 0))
  Gtk.main_quit
end
scrolled_win = Gtk::ScrolledWindow.new
scrolled_win.border_width = 5
scrolled_win.add(treeview)
scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
scrolled_win.set_size_request(550, 400)

#################################
# 各windowをひとつにまとめる
#################################
box1 = Gtk::VBox.new(false, 0)

box1.pack_start(entryarea, true, true, 0)
box1.pack_start(scrolled_win, true, true, 0)

window.add(box1)
window.show_all
Gtk.main


