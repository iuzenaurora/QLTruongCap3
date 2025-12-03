using QLTruongCap3.Models;
using System.Collections.Generic;

namespace QLTruongC3.Models
{
    // 1. ViewModel Chính Cho Dashboard (AdminDashboardViewModel)
    public class AdminDashboardViewModel
    {
        // Thống kê tổng quát (Card)
        public int TongHocSinh { get; set; }
        public int TongGiaoVien { get; set; }
        public int TongLopHoc { get; set; }

        // Thông tin năm học hiện tại
        public string CurrentYear { get; set; }
        public string CurrentSemester { get; set; }

        // Dữ liệu cho Biểu đồ Sĩ số (JSON string để pass sang JS)
        public string ChartLabelsKhoi { get; set; }
        public string ChartDataSiSo { get; set; }

        // Dữ liệu cho Biểu đồ Học lực (JSON string)
        public string ChartDataHocLucGioi { get; set; }
        public string ChartDataHocLucKha { get; set; }
        public string ChartDataHocLucTB { get; set; }
        public string ChartDataHocLucYeu { get; set; }

        // Các property hỗ trợ tương thích ngược (nếu Controller cũ có dùng)
        public List<SiSoKhoiViewModel> ClassSizeStats { get; set; }
        public List<SP_ThongKe_TrangChu_Result> SummaryStats { get; set; }
    }

    // 2. Class map kết quả từ SP_ThongKe_TrangChu
    public class ThongKeTongQuatResult
    {
        public string ChiTieu { get; set; }
        public int SoLuong { get; set; }
    }

    // 3. Class map kết quả từ FN_ThongKe_SiSoTheoKhoi
    // Đây là class bị thiếu gây ra lỗi
    public class SiSoKhoiViewModel
    {
        public string TENKHOI { get; set; }
        public int TongSiSo { get; set; }
    }

    // 4. Class map kết quả từ SP_ThongKe_XepLoaiTheoKhoi
    public class XepLoaiKhoiResult
    {
        public string TENKHOI { get; set; }
        public string XepLoai { get; set; }
        public int SoLuong { get; set; }
    }

    // 5. Class ViewModel phụ cho Học lực (nếu cần dùng dạng List thay vì JSON)
    public class HocLucKhoiViewModel
    {
        public string TENKHOI { get; set; }
        public string XepLoai { get; set; }
        public int SoLuong { get; set; }
    }
}