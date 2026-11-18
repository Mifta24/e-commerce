module ApplicationHelper
  # Format harga ke Rupiah, contoh: 42000 => "Rp42.000"
  def rupiah(amount)
    "Rp#{number_with_delimiter(amount, delimiter: '.')}"
  end

  # Warna pastel yang stabil per record (berdasarkan id), dipakai sebagai latar gambar placeholder.
  def tone_for(record)
    %w[pink yellow lilac][record.id.to_i % 3]
  end
end
