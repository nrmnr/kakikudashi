#! ruby
# coding: utf-8

# ref:
# http://kou.benesse.co.jp/nigate/japanese/a13j0305.html
# http://kou.benesse.co.jp/nigate/japanese/a13j0306.html

class Kunten
  def initialize node, seq
    @kanji, @kana, @kaeri = node.scan(/^([^ァ-ヶ\[\]]+)([ァ-ヶ]+)?(?:\[(.+)\])?$/).flatten.map(&:to_s)
    raise to_s if @kaeri =~ /^\|/ and !@kana.empty?
    @seq = seq
    @read_times = 0
  end
  attr_reader :kanji, :kana, :kaeri, :seq
  attr_writer :kaeri

  def read
    @read_times += 1
  end

  def to_raw
    if @kaeri.empty?
      "#{@kanji}#{@kana}"
    else
      "#{@kanji}#{@kana}[#{@kaeri}]"
    end
  end

  def to_s
    if @kanji =~ /[。、]/
      @kanji
    else
      "%s(%s)[%s]" % [@kanji, @kana, @kaeri]
    end
  end

  def to_kan_furi index
    case @kanji
    when "不"
      case @kana
      when "","ンバ","シテ"; return "ず" + furigana
      when /^ルヲ?$/; return "ざ" + furigana
      else raise self.to_s
      end
    when "弗"
      return "ず" if @kana.empty?
    when "可"
      return "べ" + furigana
    when "使", "令"
      return "しむ" if @kana == "ム"
    when "見", "被"
      return "る" if @kana.empty?
    when "如"
      return "ごとし" if @kana == "シ"
    when "若"
      if @kana == "シ"
        return "もし" if index.zero?
        return "ごとし"
      end
      return "なんぢ" if @kana.empty?
    when "也"
      return "なり" if @kana.empty?
    when "之"
      return "の" if @kana.empty?
    when "由"
      return "より" if @kana.empty?
    when "自", "従"
      return "より" if @kana == "リ"
    when "与"
      return "と" if @kana.empty?
    when "者"
      return "は" if @kana.empty?
    when "乎", "哉", "邪"
      return "や" if @kana.empty?
    when "耳"
      return "のみ" if @kana.empty?
    when "将"
      return "す" if @read_times == 2 and @kana == "ニ"
    when "未"
      return "ず" if @read_times == 2 and @kana == "ダ"
    when /[而焉矣於于乎]/
      return "" if @kana.empty?
    end
    return @kanji + furigana
  end

  def is_saidoku
    return true if @kanji == "将" and @kaeri == "レ" and @kana == "ニ"
    return true if @kanji == "未" and @kaeri == "レ" and @kana == "ダ"
    return false
  end

  def furigana
    @kana.tr("ァ-ン", "ぁ-ん")
  end
end

class Kakikudashi
  def conv genbun
    kunten_nodes = kuntens genbun
    kunten_nodes = punc_hyphen kunten_nodes
    seq = kakikudashi kunten_nodes
    seq.join(" / ")
    kaki = []
    seq.each_with_index{|node, i|
      node.read
      kaki << node.to_kan_furi(i)
    }
    kaki.join
  end

  def kuntens genbun
    i = 0
    genbun.split(/\s+/).map{|node|
      i += 1
      Kunten.new node, i
    }
  end

  def punc_hyphen kunten_nodes
    arr = []
    i = 0
    index = 0
    while i < kunten_nodes.size
      node = kunten_nodes[i]
      if node.kaeri =~ /^\|/
        raise node.to_s + kunten_nodes[i+1].to_s unless kunten_nodes[i+1].kaeri.empty?
        kanji = node.kanji + kunten_nodes[i+1].kanji
        kaeri = node.kaeri.sub(/\|/, "")
        kana = kunten_nodes[i+1].kana
        arr << Kunten.new("#{kanji}#{kana}[#{kaeri}]", index)
        i += 1 # skip next node
      else
        arr << Kunten.new(node.to_raw, index)
      end
      i += 1
      index += 1
    end
    return arr
  end

  def kakikudashi kunten_nodes
    @sequence = []
    @re_ten = []
    ni_ten = []
    jo_ten = []
    ko_ten = []
    kunten_nodes.each_with_index do |node, i|
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
      when "一レ", "上レ", "甲レ"
        @re_ten << node
        raise unless kunten_nodes[i+1]
        kunten_nodes[i+1].kaeri = node.kaeri.sub(/レ/,"")
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
    if ten_stack.empty?
      seq = @sequence.map{|node| node.to_s}.join(" - ")
      raise "stack empty:#{seq}"
    end
    push_sequence ten_stack.pop until ten_stack.empty?
  end
end

