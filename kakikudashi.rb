#! ruby
# coding: utf-8

class Kunten
  def initialize node, seq
    @kanji, @kana, @kaeri = node.scan(/^(.)([ァ-ヶ]+)?(?:\[(.+)\])?$/).flatten.map(&:to_s)
    @seq = seq
    @read_times = 0
  end
  attr_reader :kaeri, :seq

  def read
    @read_times += 1
  end

  def to_s
    if @kanji =~ /[。、]/
      @kanji
    else
      "%s(%s)[%s]" % [@kanji, @kana, @kaeri]
    end
  end

  def to_kan_furi
    case @kanji
    when "不"
      case @kana
      when "","ンバ","シテ"; return "ず" + furigana
      when /^ルヲ?$/; return "ざ" + furigana
      else raise self.to_s
      end
    when "将"
      return "す" if @read_times == 2 and @kana == "ニ"
    when "也"
      return "なり" if @kana == ""
    when "可"
      return "べ" + furigana
    when "乎"
      return "や" if @kana == ""
    when "於"
      return "" if @kana == ""
    end
    return @kanji + furigana
  end

  def is_saidoku
    return true if @kanji == "将" and @kaeri == "レ" and @kana == "ニ"
    return false
  end

  def furigana
    @kana.tr("ァ-ン", "ぁ-ん")
  end
end

class Kakikudashi
  def conv genbun
    kunten_nodes = kuntens genbun
    seq = kakikudashi kunten_nodes
    seq.join(" / ")
    seq.map{|node|
      node.read
      node.to_kan_furi
    }.join
  end

  def kuntens genbun
    i = 0
    genbun.split(/\s+/).map{|node|
      i += 1
      Kunten.new node, i
    }
  end

  def kakikudashi kunten_nodes
    @sequence = []
    @re_ten = []
    ni_ten = []
    jo_ten = []
    ko_ten = []
    kunten_nodes.each do |node|
      case node.kaeri
      when "レ"
        @re_ten << node
        push_sequence node if node.is_saidoku
      when "二", "三"
        ni_ten << node
      when "一"
        push_sequence node
        flush ni_ten
      when "中", "下"
        jo_ten << node
      when "上"
        push_sequence node
        flush jo_ten
      when "乙", "丙", "丁"
        ko_ten << node
      when "甲"
        push_sequence node
        flush ko_ten
      else
        push_sequence node
      end
    end
    return @sequence
  end

  def push_sequence node
    @sequence << node
    push_sequence @re_ten.pop if !@re_ten.empty? and @re_ten.last.seq == node.seq-1
  end

  def flush ten_stack
    raise "stack empty" if ten_stack.empty?
    push_sequence ten_stack.pop until ten_stack.empty?
  end
end

