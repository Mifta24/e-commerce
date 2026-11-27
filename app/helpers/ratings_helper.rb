module RatingsHelper
 # bintang(4) => "★★★★☆"; nil dianggap 0
  def bintang(nilai)
    # to_i digunakan untuk mengonversi nilai yang diterima menjadi bilangan bulat. Jika nilai adalah nil, maka akan dikonversi menjadi 0.
    n = nilai.to_i.clamp(0, 5) # kalau nil dianggap 0, dibatasi 0..5
    # "★" * n + "☆" * (5 - n) digunakan untuk membuat representasi visual dari rating bintang.
    # "★" * n + "☆" * (5 - n) => "★★★★☆"
    "★" * n + "☆" * (5 - n)
  end
end
