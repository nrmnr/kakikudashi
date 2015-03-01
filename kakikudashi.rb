#! ruby
# coding: utf-8

# ref:
# http://kou.benesse.co.jp/nigate/japanese/a13j0305.html
# http://kou.benesse.co.jp/nigate/japanese/a13j0306.html

class Kunten
  RE_KUNTEN = /^([^ァ-ヶ\[\(]+)([ァ-ヶ]*)?(\([ァ-ヶ]*\))?(\[.*\])?$/

  def initialize node, seq
    raise node unless node =~ RE_KUNTEN
    @kanji, @kana, @sai, @kaeri = node.scan(RE_KUNTEN).flatten.map(&:to_s)
    @sai.gsub! /[\(\)]/, ""
    @kaeri.gsub! /[\[\]]/, ""
    raise node if @kaeri =~ /^\|/ and !@kana.empty?
    @seq = seq
    @read_times = 0
  end
  attr_reader :kanji, :kana, :kaeri, :seq
  attr_writer :kaeri

  def read
    @read_times += 1
  end

  def to_s
    "%s%s(%s)[%s]" % [@kanji, @kana, @sai, @kaeri]
  end

  def to_kan_furi index
    case @kanji
    when "不"
      case @kana
      when "","ンバ","シテ"; return "ず" + furigana
      when /^ル/; return "ざ" + furigana
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

  def saidoku
    @sai.tr("ァ-ン", "ぁ-ん")
  end

  def furigana
    @kana.tr("ァ-ン", "ぁ-ん")
  end
end

class Sequence
  include Enumerable

  def initialize nodes = nil, kaeri = nil
    @kaeri = kaeri
    if nodes.nil?
      @nodes = []
    else
      @nodes = [nodes].flatten
    end
  end
  attr_reader :nodes, :kaeri

  def << node
    @nodes << node
  end

  def each
    @nodes.each do |node|
      if node.is_a? Sequence
        node.each do |n|
          yield n
        end
      else
        yield node
      end
    end
  end
end

class Kakikudashi
  def conv genbun
    @kunten_nodes = get_kunten_nodes genbun
    # kunten_nodes = punc_hyphen kunten_nodes
    seq = build_sequence
    kaki = []
    seq.each_with_index{|node, i|
      node.read
      kaki << node.to_kan_furi(i)
    }
    kaki.join
  end

  def get_kunten_nodes genbun
    i = -1
    genbun.split(/\s+/).map{|node|
      i += 1
      Kunten.new node, i
    }
  end

  def build_sequence
    begin
      @sequence = Sequence.new
      @re_ten = {}
      @ni_ten_stack = []
      proc_node 0
      return @sequence
    rescue => e
      warn sequence_str
      raise e
    end
  end

  def proc_node i
    node = @kunten_nodes[i]
    return if node.nil?

    case node.kaeri
    when "レ"
      raise if @kunten_nodes[i+1].nil?
      @re_ten[node.seq] = node
      push_sequence node if node.is_saidoku
    when /^[二三四中下乙丙丁地人]$/
      @ni_ten_stack << node
    when /^[一上甲天]$/
      push_sequence node
      flush_ni_ten node.kaeri
    when "一レ", "上レ", "甲レ", "天レ"
      next_node = @kunten_nodes[i+1]
      raise if next_node.nil?
      if next_node.kaeri.empty?
        push_sequence next_node
        push_sequence node
        flush_ni_ten node.kaeri
        proc_node i+2
        return
      else
        # todo
      end
    when /^\|(.)$/
      kaeri = $1
      next_node = @kunten_nodes[i+1]
      raise if next_node.nil?
      seq = Sequence.new([node, next_node], kaeri)
      case kaeri
      when /^[二三四中下乙丙丁地人]$/
        @ni_ten_stack << seq
        proc_node i+2
      when /^[一上甲天]$/
        push_sequence seq
        flush_ni_ten kaeri
        proc_node i+2
      else
        raise
      end
      return
    else
      push_sequence node
    end
    proc_node i+1
  end

  def flush_ni_ten series
    re_series = case series
                when /一/; /[二三四]/
                when /上/; /[中下]/
                when /甲/; /[乙丙丁]/
                when /天/; /[地人]/
                end
    until @ni_ten_stack.empty?
      return unless @ni_ten_stack.last.kaeri =~ re_series
      push_sequence @ni_ten_stack.pop
    end
  end

  def push_sequence node
    if node.is_a? Sequence
      node.nodes.each do |n|
        push_sequence n
      end
      return
    end
    @sequence << node
    if @re_ten.key? node.seq-1
      push_sequence @re_ten[node.seq-1]
      @re_ten.delete node.seq-1
    end
  end

  def sequence_str
    @sequence.map{|node| node.to_s}.join(" - ")
  end
end

