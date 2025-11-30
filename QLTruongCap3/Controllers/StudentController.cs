using QLTruongCap3.Models;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web.Mvc;
using System.Web.Routing;

namespace QLTruongC3.Controllers
{
    [Authorize(Roles = "HS")]
    public class StudentController : Controller
    {
        private QLTRUONGC3Entities db = new QLTRUONGC3Entities();

        // --- FIX LỖI: Ép buộc hệ thống dùng dấu chấm (.) cho số thập phân ---
        // Giống bên TeacherController, giúp hiển thị điểm số chuẩn xác (VD: 8.5 thay vì 8,5)
        protected override void Initialize(RequestContext requestContext)
        {
            base.Initialize(requestContext);
            CultureInfo ci = new CultureInfo("en-US");
            Thread.CurrentThread.CurrentCulture = ci;
            Thread.CurrentThread.CurrentUICulture = ci;
        }

        private string GetCurrentMaHS()
        {
            var username = User.Identity.Name;
            var user = db.TAIKHOAN.FirstOrDefault(u => u.USERNAME == username);
            return user?.MAHS;
        }

        public ActionResult Index()
        {
            var maHS = GetCurrentMaHS();
            if (maHS == null) return RedirectToAction("Login", "Account");
            var hs = db.HOCSINH.Find(maHS);
            return View(hs);
        }

        // Cập nhật Action XemDiem để hỗ trợ xem chi tiết theo học kỳ
        public ActionResult XemDiem(string maNam, string maHK)
        {
            var maHS = GetCurrentMaHS();
            if (maHS == null) return RedirectToAction("Login", "Account");

            // 1. Xử lý tham số mặc định
            if (string.IsNullOrEmpty(maNam)) maNam = "2024-2025"; // Có thể lấy năm hiện tại từ DB
            if (string.IsNullOrEmpty(maHK)) maHK = "HK1";

            // 2. Chuẩn bị dữ liệu cho Dropdown
            ViewBag.MaNam = new SelectList(db.NAMHOC, "MANAM", "TENNAM", maNam);
            ViewBag.SelectedHK = maHK;
            ViewBag.SelectedNam = maNam;

            // 3. Lấy bảng điểm tổng hợp (Phần trên giao diện - Tổng kết, Xếp loại)
            var bangDiemTongHop = db.sp_GetBangDiemTongHop(maHS, maNam).FirstOrDefault();

            // 4. Lấy bảng điểm chi tiết (Phần dưới giao diện - Bảng điểm chi tiết)
            // LƯU Ý: Bạn cần Update Model .edmx để có hàm sp_HS_XemDiemChiTiet trước khi chạy dòng này
            var bangDiemChiTiet = db.sp_HS_XemDiemChiTiet(maHS, maNam, maHK).ToList();

            // Truyền danh sách chi tiết qua ViewBag
            ViewBag.ChiTietDiem = bangDiemChiTiet;

            return View(bangDiemTongHop);
        }

        // --- CẬP NHẬT ACTION THỜI KHÓA BIỂU ---
        public ActionResult ThoiKhoaBieu(string maNam, string maHK)
        {
            var maHS = GetCurrentMaHS();
            if (maHS == null) return RedirectToAction("Login", "Account");

            // 1. Xử lý tham số mặc định (Nếu null thì lấy giá trị hiện tại)
            if (string.IsNullOrEmpty(maNam)) maNam = "2024-2025";
            if (string.IsNullOrEmpty(maHK)) maHK = "HK1";

            // 2. Tạo Dropdown cho View
            ViewBag.MaNam = new SelectList(db.NAMHOC, "MANAM", "TENNAM", maNam);
            ViewBag.SelectedHK = maHK;
            ViewBag.SelectedNam = maNam;

            // 3. Gọi Stored Procedure lấy TKB
            // Lưu ý: Cần Update Model .edmx để có hàm sp_HS_XemThoiKhoaBieu
            var tkbList = db.sp_HS_XemThoiKhoaBieu(maHS, maNam, maHK).ToList();

            return View(tkbList);
        }
    }
}