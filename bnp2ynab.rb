#!/usr/bin/ruby
#encoding: UTF-8

require 'csv'

def handle_file(in_path)
  # Skip non-CSV file extensions.
  return if !in_path.end_with?(".csv")

  out_filename = File.basename(in_path, '.*') + '.YNAB.csv'
  out_path = File.join(File.dirname(in_path), 'YNAB', out_filename)
  ensure_directory(out_path)

  File.open(in_path, "r:ISO-8859-1") do |in_io|
    File.open(out_path, 'w') do |out_io|
      BnpToYnab.convert(in_io, out_io)
    end
  end

  File.delete(in_path)
end

def ensure_directory(path)
  dirname = File.dirname(path)
  if !File.directory?(dirname)
    Dir.mkdir(dirname)
  end
end

module BnpToYnab
  def self.convert(in_io, out_io)
    out_io << Transaction.ynab_header
    Transaction.each(in_io) do |trx|
      out_io << trx.to_ynab
    end
  end

  class Transaction
    def self.each(io)
      # The BNP CSV starts with two bogus lines: a summary (dates covered,
      # total of amounts), and a line of empty values. Fortunately, we can skip
      # them with a regex, and CSV will parse the first non-skipped line as a
      # line of headers.
      opts = {
        :headers => true,
        :skip_lines => /(?:^Compte)|^,{4}/
      }

      CSV.new(io, opts).each do |row|
        yield Transaction.new(row)
      end
    end

    def self.ynab_header
      ['Date', 'Payee', 'Memo', 'Outflow', 'Inflow'].to_csv
    end

    def initialize(row)
      @date = Date.parse(row['Date operation'])
      @memo = row['Libelle operation']
      @name = BnpToYnab.parse_name(@memo)
      @category = BnpToYnab.parse_category(row['Categorie operation'])
      @amount, @type = BnpToYnab.parse_amount(row['Montant operation'])
      @outflow = self.type === :outflow ? self.amount : 0.00
      @inflow = self.type === :inflow ? self.amount : 0.00
    end

    attr_reader :date, :name, :type, :amount, :memo, :outflow, :inflow

    # Date,Payee,Category,Memo,Outflow,Inflow
    def to_ynab
      [
        @date.strftime('%Y-%m-%d'),
        @name,
        @memo,
        sprintf('%.2f', @outflow),
        sprintf('%.2f', @inflow),
      ].to_csv
    end
  end

  def self.parse_name(str)
    [
      method(:parse_facture),
      method(:parse_retrait),
      method(:parse_prlv),
      method(:parse_de),
      method(:parse_ben),
    ].each do |p|
      name = p.(str)
      return name if !name.nil?
    end
    str
  end

  def self.parse_de(str)
    # VIR SEPA RECU /DE SOMEBODY /MOTIF SOMETHING.
    m = %r{/DE ((?:[^/]|/(?!MOTIF))*)}.match(str)
    m.nil? ? m : m[1].strip
  end

  def self.parse_ben(str)
    # VIREMENT SEPA EMIS /MOTIF SOMETHING /BEN SOMEBODY /RE
    m = %r{/BEN ((?:[^/]|/(?!RE))*)}.match(str)
    m.nil? ? m : m[1].strip
  end

  def self.parse_prlv(str)
    # PRLV SEPA SOMEONE 99999 ECH/271218 ID EMET
    m = %r{^PRLV SEPA ((?:[^E]|E(?!CH))*)}.match(str)
    m.nil? ? m : m[1].strip
  end

  def self.parse_facture(str)
    # FACTURE CARTE DU 261218 SOMEWHERE CARTE 9999XXXXX
    # FACTURE CARTE DU 261218 SOMEWHERE CARTE
    # FACTURE CARTE DU 261218 SOMEWHERE CAR
    m = %r{^FACTURE CARTE DU \d+ ((?:[^E]|E(?!CH))*)}.match(str)
    m.nil? ? m : m[1].gsub(/CART?E? ?\d*X*/, '').strip
  end

  def self.parse_retrait(str)
    # RETRAIT DAB 23/12/18 10H59 99999999 SOMEWHERE
    m = %r{^RETRAIT DAB \d+/\d+/\d+ \d+H\d+ \d+ (.*)}.match(str)
    m.nil? ? m : m[1]
  end

  def self.parse_category(str)
    str === 'Non défini' ? '' : str
  end

  # BNP exports prices that look like normal floats, so all we need to do is
  # convert them.
  def self.parse_amount(str)
    amount = str.to_f
    type = amount < 0 ? :outflow : :inflow
    [amount.abs, type]
  end
end

begin
  ARGV.each { |in_path| handle_file(in_path) }
rescue Interrupt
end
