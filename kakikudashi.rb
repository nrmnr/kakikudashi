#! ruby
# coding: utf-8

# ref:
# http://kou.benesse.co.jp/nigate/japanese/a13j0305.html
# http://kou.benesse.co.jp/nigate/japanese/a13j0306.html

class Kunten
  def initialize node, seq
    @kanji, @kana, @sai, @kaeri = *node.scan(/^([^ァ-ヶ\[\(]+)([ァ-ヶ]+)?(?:\((.+)\))?(?:\[(.+)\])?$/).flatten.map(&:to_s)
    raise to_s if @kaeri =~ /^\|/ and !@kana.empty?
    @seq = seq
    @read_times = 0
  end
  attr_reader :kaeri

  def to_s
    "%s%s(%s)[%s]" % [@kanji, @kana, @sai, @kaeri]
  end

  def read
    @read_times += 1
  end

  def to_kan_furi index
    raise self if @read_times > 2
    return to_kan_furi_saidoku if @read_times == 2

    case @kanji
    when "不"
      case @kana
      when "","ンバ","シテ"; return "ず" + furigana
      when /^[ラリルレ]/; return "ざ" + furigana
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
        return index.zero? ? "もし" : "ごとし"
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
    end
    return @kanji + furigana
  end

  def to_kan_furi_saidoku
    case @kanji
    when "将"
      return "す" + saidoku
    when "当"
      return "べ" + saidoku
    when "須"
      return "べ" + saidoku
    when "猶"
      return "ごと" + saidoku
    when "未"
      return @sai.empty? ? "ず" : "ざ" + saidoku
    end
  end

  def saidoku?
    return true unless @sai.empty?
    return true if @kanji == "将" and @kana == "ニ"
    return true if @kanji == "当" and @kana == "ニ"
    return true if @kanji == "須" and @kana == "ラク"
    return true if @kanji == "猶" and @kana == "ホ"
    return true if @kanji == "未" and @kana == "ダ"
    return false
  end

  def furigana
    @kana.tr("ァ-ン", "ぁ-ん")
  end

  def saidoku
    @sai.tr("ァ-ン", "ぁ-ん")
  end
end

class Kakikudashi
  KAERITEN_MAP = {
    "一" => /二/, "二" => /三/, "三" => /四/, "四" => /■/,
    "上" => /[中下]/, "中" => /下/, "下" => /■/,
    "甲" => /乙/, "乙" => /丙/, "丙" => /丁/, "丁" => /■/,
    "天" => /地/, "地" => /人/, "人" => /■/
  } # ■：番兵

  def conv genbun
    return "" if genbun.empty?
    @kunten_nodes = get_kuntens genbun
    @kunten_nodes.unshift nil # 番兵
    build_sequence
    kaki = []
    @sequence.each_with_index{|node, i|
      node.read
      kaki << node.to_kan_furi(i-1)
    }
    return replace_nomi kaki.join
  end

  def get_kuntens genbun
    i = -1
    genbun.split(/\s+/).map{|node|
      i += 1
      Kunten.new node, i
    }
  end

  def build_sequence
    @sequence = []
    forward 1
  end

  def forward i
    node = @kunten_nodes[i]
    return if node.nil?
    prev_node = @kunten_nodes[i-1]
    case node.kaeri
    when "レ", /^[一上甲天]レ$/, /^[二三四中下乙丙丁地人]$/
      @sequence << node if node.saidoku?
      forward i+1
    when /^\|/
      forward i+2
    when /^[一上甲天]$/
      push_sequence i
      backward i-1, KAERITEN_MAP[node.kaeri]
      forward i+1
    else
      push_sequence i
      forward i+1
    end
  end

  def backward i, series
    node = @kunten_nodes[i]
    return if node.nil?
    unless node.kaeri =~ series
      backward i-1, series
      return
    end
    prev_node = @kunten_nodes[i-1]
    next_node = @kunten_nodes[i+1]
    if prev_node.nil?
      push_sequence i
    elsif node.kaeri =~ /^\|/
      push_sequence i
      backward i-1, KAERITEN_MAP[node.kaeri.sub(/^\|/, "")]
    else
      push_sequence i
      if prev_node.kaeri =~ /レ/
        backward i-2, KAERITEN_MAP[node.kaeri]
      else
        backward i-1, KAERITEN_MAP[node.kaeri]
      end
    end
  end

  def push_sequence i
    node = @kunten_nodes[i]
    if node.kaeri =~ /^\|/
      next_node = @kunten_nodes[i+1]
      raise unless next_node
      @sequence << node
      @sequence << next_node
      return
    end
    @sequence << node
    prev_node = @kunten_nodes[i-1]
    if prev_node and prev_node.kaeri =~ /レ/
      push_sequence i-1
    end
    if node.kaeri =~ /^[一上甲天]レ$/
      backward i-1, KAERITEN_MAP[node.kaeri.gsub(/[\|レ]/, "")]
    end
  end

  def replace_nomi kaki
    kaki.gsub! /而已[矣焉耳]/, "のみ"
    kaki.gsub! /耳(?![一-龠])/u, "のみ"
    kaki.gsub! /[而焉矣於于乎]/, ""
    return kaki
  end
end

