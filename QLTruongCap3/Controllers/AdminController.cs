using QLTruongCap3.Models;
using System.Data.Entity;
using System.Linq;
using System.Web.Mvc;

namespace QLTruongC3.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private QLTRUONGC3Entities db = new QLTRUONGC3Entities();

        // Trang chủ: Thống kê
        public ActionResult Index()
        {
            // Gọi Stored Procedure thống kê
            var thongKe = db.SP_ThongKe_TrangChu().ToList();
            return View(thongKe);
        }

        // Quản lý Lớp (Tìm kiếm)
        public ActionResult QuanLyLop(string searchMaLop, string searchMaKhoi)
        {
            ViewBag.MaKhoiList = new SelectList(db.KHOI, "MAKHOI", "TENKHOI");

            var query = db.LOP.Include(l => l.GIAOVIEN).AsQueryable();

            if (!string.IsNullOrEmpty(searchMaLop)) query = query.Where(l => l.MALOP.Contains(searchMaLop));
            if (!string.IsNullOrEmpty(searchMaKhoi)) query = query.Where(l => l.MAKHOI == searchMaKhoi);

            return View(query.ToList());
        }

        // Bạn có thể thêm các Action Create/Edit/Delete ở đây
        public ActionResult QuanLyGiaoVien() { return View(db.GIAOVIEN.ToList()); }
        public ActionResult QuanLyHocSinh() { return View(db.HOCSINH.ToList()); }
        public ActionResult QuanLyMonHoc() { return View(db.MONHOC.ToList()); }
        public ActionResult QuanLyTaiKhoan() { return View(db.TAIKHOAN.ToList()); }
        public ActionResult QuanLyTKB() { return View(db.THOIKHOABIEU.ToList()); }
    }
}
