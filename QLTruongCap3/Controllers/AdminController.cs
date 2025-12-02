using QLTruongCap3.Models;
using System;
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
            try 
            {
                var thongKe = db.Database.SqlQuery<SP_ThongKe_TrangChu_Result>("EXEC SP_ThongKe_TrangChu").ToList();
                return View(thongKe);
            }
            catch
            {
                return View(new System.Collections.Generic.List<SP_ThongKe_TrangChu_Result>());
            }
        }

        // ==========================================================
        // QUẢN LÝ LỚP HỌC
        // ==========================================================

        public ActionResult QuanLyLop(string searchMaLop, string searchMaKhoi)
        {
            ViewBag.MaKhoiList = new SelectList(db.KHOI, "MAKHOI", "TENKHOI");
            ViewBag.CurrentFilterMaLop = searchMaLop;
            ViewBag.CurrentFilterMaKhoi = searchMaKhoi;

            var query = db.LOP.Include(l => l.GIAOVIEN).Include(l => l.KHOI).AsQueryable();

            if (!string.IsNullOrEmpty(searchMaLop)) query = query.Where(l => l.MALOP.Contains(searchMaLop));
            if (!string.IsNullOrEmpty(searchMaKhoi)) query = query.Where(l => l.MAKHOI == searchMaKhoi);

            return View(query.OrderBy(l => l.TENLOP).ToList());
        }

        public ActionResult ThemLop()
        {
            ViewBag.MAKHOI = new SelectList(db.KHOI, "MAKHOI", "TENKHOI");
            ViewBag.MAGVCN = new SelectList(db.GIAOVIEN.Where(g => g.TRANGTHAI == "Đang làm"), "MAGV", "HOTEN");
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemLop([Bind(Include = "MALOP,TENLOP,MAKHOI,MAGVCN")] LOP lop)
        {
            if (ModelState.IsValid)
            {
                if (db.LOP.Any(l => l.MALOP == lop.MALOP))
                {
                    ModelState.AddModelError("MALOP", "Mã lớp này đã tồn tại.");
                }
                else
                {
                    try
                    {
                        lop.SISO = 0;
                        db.LOP.Add(lop);
                        db.SaveChanges();
                        TempData["SuccessMessage"] = "Thêm lớp mới thành công!";
                        return RedirectToAction("QuanLyLop");
                    }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("", "Có lỗi xảy ra: " + ex.Message);
                    }
                }
            }
            ViewBag.MAKHOI = new SelectList(db.KHOI, "MAKHOI", "TENKHOI", lop.MAKHOI);
            ViewBag.MAGVCN = new SelectList(db.GIAOVIEN.Where(g => g.TRANGTHAI == "Đang làm"), "MAGV", "HOTEN", lop.MAGVCN);
            return View(lop);
        }

        public ActionResult SuaLop(string id)
        {
            if (id == null) return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            LOP lop = db.LOP.Find(id);
            if (lop == null) return HttpNotFound();

            ViewBag.MAKHOI = new SelectList(db.KHOI, "MAKHOI", "TENKHOI", lop.MAKHOI);
            ViewBag.MAGVCN = new SelectList(db.GIAOVIEN.Where(g => g.TRANGTHAI == "Đang làm"), "MAGV", "HOTEN", lop.MAGVCN);
            return View(lop);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaLop([Bind(Include = "MALOP,TENLOP,MAKHOI,MAGVCN,SISO")] LOP lop)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    db.Entry(lop).State = EntityState.Modified;
                    db.SaveChanges();
                    TempData["SuccessMessage"] = "Cập nhật thông tin lớp thành công!";
                    return RedirectToAction("QuanLyLop");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi cập nhật: " + ex.Message);
                }
            }
            ViewBag.MAKHOI = new SelectList(db.KHOI, "MAKHOI", "TENKHOI", lop.MAKHOI);
            ViewBag.MAGVCN = new SelectList(db.GIAOVIEN.Where(g => g.TRANGTHAI == "Đang làm"), "MAGV", "HOTEN", lop.MAGVCN);
            return View(lop);
        }

        // 6. Xóa lớp - Đã SỬA LỖI (Thêm kiểm tra Phân Công)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult XoaLop(string id)
        {
            try
            {
                LOP lop = db.LOP.Find(id);
                if (lop != null)
                {
                    // Kiểm tra các ràng buộc dữ liệu:
                    bool coHocSinh = db.Database.SqlQuery<int>("SELECT COUNT(*) FROM HOCSINH_NAMHOC WHERE MALOP = @p0", id).Single() > 0;
                    bool coTKB = db.THOIKHOABIEU.Any(t => t.MALOP == id);
                    
                    // MỚI: Kiểm tra bảng Phân Công (Rất quan trọng)
                    bool coPhanCong = db.Database.SqlQuery<int>("SELECT COUNT(*) FROM PHANCONG WHERE MALOP = @p0", id).Single() > 0;

                    if (coHocSinh)
                    {
                        TempData["ErrorMessage"] = "Không thể xóa: Lớp này đang có học sinh theo học!";
                    }
                    else if (coTKB)
                    {
                        TempData["ErrorMessage"] = "Không thể xóa: Lớp này đã được xếp thời khóa biểu!";
                    }
                    else if (coPhanCong)
                    {
                        TempData["ErrorMessage"] = "Không thể xóa: Lớp này đã được phân công giáo viên giảng dạy!";
                    }
                    else
                    {
                        db.LOP.Remove(lop);
                        db.SaveChanges();
                        TempData["SuccessMessage"] = "Xóa lớp thành công!";
                    }
                }
            }
            catch (Exception ex)
            {
                // Hiển thị chi tiết lỗi nếu có lỗi khác
                var innerMessage = ex.InnerException != null ? ex.InnerException.Message : "";
                TempData["ErrorMessage"] = "Lỗi hệ thống khi xóa: " + ex.Message + " " + innerMessage;
            }
            return RedirectToAction("QuanLyLop");
        }

        public ActionResult QuanLyGiaoVien() { return View(db.GIAOVIEN.ToList()); }
        public ActionResult QuanLyHocSinh() { return View(db.HOCSINH.ToList()); }
        public ActionResult QuanLyMonHoc() { return View(db.MONHOC.ToList()); }
        public ActionResult QuanLyTaiKhoan() { return View(db.TAIKHOAN.ToList()); }
        public ActionResult QuanLyTKB() { return View(db.THOIKHOABIEU.ToList()); }
    }
}