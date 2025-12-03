using QLTruongC3.Models;
using QLTruongCap3.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web.Mvc;
using System.Web.Script.Serialization;

namespace QLTruongC3.Controllers
{
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private QLTRUONGC3Entities db = new QLTRUONGC3Entities();

        // ==========================================================
        // TRANG CHỦ: THỐNG KÊ DASHBOARD
        // ==========================================================
        public ActionResult Index()
        {
            var model = new AdminDashboardViewModel();
            var serializer = new JavaScriptSerializer();

            try
            {
                // 1. Thống kê tổng quan
                var summaryData = db.Database.SqlQuery<ThongKeTongQuatResult>("EXEC SP_ThongKe_TrangChu").ToList();
                var hsObj = summaryData.FirstOrDefault(x => x.ChiTieu == "Tổng số học sinh");
                var gvObj = summaryData.FirstOrDefault(x => x.ChiTieu == "Tổng số giáo viên");
                var lopObj = summaryData.FirstOrDefault(x => x.ChiTieu == "Tổng số lớp");

                model.TongHocSinh = hsObj != null ? hsObj.SoLuong : 0;
                model.TongGiaoVien = gvObj != null ? gvObj.SoLuong : 0;
                model.TongLopHoc = lopObj != null ? lopObj.SoLuong : 0;

                // 2. Biểu đồ thống kê
                var currentYear = db.NAMHOC.OrderByDescending(n => n.NGAYKETTHUC).FirstOrDefault();
                var currentSem = "HK1";

                if (currentYear != null)
                {
                    model.CurrentYear = currentYear.TENNAM;
                    model.CurrentSemester = currentSem;

                    var sisoData = db.Database.SqlQuery<SiSoKhoiViewModel>("SELECT * FROM dbo.FN_ThongKe_SiSoTheoKhoi()").ToList();
                    var labels = sisoData.Select(x => x.TENKHOI).ToList();
                    var values = sisoData.Select(x => x.TongSiSo).ToList();

                    model.ChartLabelsKhoi = serializer.Serialize(labels);
                    model.ChartDataSiSo = serializer.Serialize(values);

                    var hoclucRaw = db.Database.SqlQuery<XepLoaiKhoiResult>(
                        "EXEC SP_ThongKe_XepLoaiTheoKhoi @MANAM, @MAHK",
                        new System.Data.SqlClient.SqlParameter("@MANAM", currentYear.MANAM),
                        new System.Data.SqlClient.SqlParameter("@MAHK", currentSem)
                    ).ToList();

                    var dataGioi = new List<int>();
                    var dataKha = new List<int>();
                    var dataTB = new List<int>();
                    var dataYeu = new List<int>();

                    foreach (var khoi in labels)
                    {
                        dataGioi.Add(hoclucRaw.Where(x => x.TENKHOI == khoi && x.XepLoai == "Giỏi").Select(x => x.SoLuong).FirstOrDefault());
                        dataKha.Add(hoclucRaw.Where(x => x.TENKHOI == khoi && x.XepLoai == "Khá").Select(x => x.SoLuong).FirstOrDefault());
                        dataTB.Add(hoclucRaw.Where(x => x.TENKHOI == khoi && x.XepLoai == "Trung bình").Select(x => x.SoLuong).FirstOrDefault());
                        var yeu = hoclucRaw.Where(x => x.TENKHOI == khoi && (x.XepLoai == "Yếu" || x.XepLoai == "Kém" || x.XepLoai == "Yếu/Kém")).Sum(x => x.SoLuong);
                        dataYeu.Add(yeu);
                    }

                    model.ChartDataHocLucGioi = serializer.Serialize(dataGioi);
                    model.ChartDataHocLucKha = serializer.Serialize(dataKha);
                    model.ChartDataHocLucTB = serializer.Serialize(dataTB);
                    model.ChartDataHocLucYeu = serializer.Serialize(dataYeu);
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Lỗi tải dữ liệu: " + ex.Message;
            }

            return View(model);
        }

        // ==========================================================
        //                QUẢN LÝ GIÁO VIÊN
        // ==========================================================
        public ActionResult QuanLyGiaoVien(string searchMaGV, string searchTenGV, string searchChuyenMon, string searchTrangThai)
        {
            var listMaGV = db.GIAOVIEN.Select(g => new { g.MAGV, DisplayText = g.MAGV + " - " + g.HOTEN }).ToList();
            ViewBag.MaGVList = new SelectList(listMaGV, "MAGV", "DisplayText");
            var listChuyenMon = db.GIAOVIEN.Select(g => g.CHUYENMON).Distinct().ToList();
            ViewBag.ChuyenMonList = new SelectList(listChuyenMon);
            ViewBag.TrangThaiList = new SelectList(new[] { "Đang làm", "Nghỉ hưu", "Tạm nghỉ" });

            ViewBag.CurrentFilterMa = searchMaGV;
            ViewBag.CurrentFilterTen = searchTenGV;
            ViewBag.CurrentFilterChuyenMon = searchChuyenMon;
            ViewBag.CurrentFilterTrangThai = searchTrangThai;

            var query = db.GIAOVIEN.AsQueryable();

            if (!string.IsNullOrEmpty(searchMaGV)) query = query.Where(g => g.MAGV == searchMaGV);
            if (!string.IsNullOrEmpty(searchTenGV)) query = query.Where(g => g.HOTEN.Contains(searchTenGV));
            if (!string.IsNullOrEmpty(searchChuyenMon)) query = query.Where(g => g.CHUYENMON == searchChuyenMon);
            if (!string.IsNullOrEmpty(searchTrangThai)) query = query.Where(g => g.TRANGTHAI == searchTrangThai);

            return View(query.OrderBy(g => g.HOTEN).ToList());
        }

        public ActionResult ThemGiaoVien()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemGiaoVien(GIAOVIEN gv)
        {
            if (ModelState.IsValid)
            {
                if (db.GIAOVIEN.Any(x => x.MAGV == gv.MAGV))
                {
                    ModelState.AddModelError("MAGV", "Mã giáo viên này đã tồn tại.");
                    return View(gv);
                }
                try
                {
                    db.GIAOVIEN.Add(gv);
                    db.SaveChanges();
                    TempData["Message"] = "Thêm giáo viên thành công! Tài khoản tự động được tạo (MK: Ngày sinh).";
                    return RedirectToAction("QuanLyGiaoVien");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi hệ thống: " + ex.Message);
                }
            }
            return View(gv);
        }

        public ActionResult SuaGiaoVien(string id)
        {
            if (string.IsNullOrEmpty(id)) return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            var gv = db.GIAOVIEN.Find(id);
            if (gv == null) return HttpNotFound();
            return View(gv);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaGiaoVien(GIAOVIEN gv)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    db.Entry(gv).State = EntityState.Modified;
                    db.SaveChanges();
                    TempData["Message"] = "Cập nhật giáo viên thành công!";
                    return RedirectToAction("QuanLyGiaoVien");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi cập nhật: " + ex.Message);
                }
            }
            return View(gv);
        }

        public ActionResult XoaGiaoVien(string id)
        {
            var gv = db.GIAOVIEN.Find(id);
            if (gv == null) return HttpNotFound();
            return View(gv);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult XacNhanXoaGiaoVien(string MAGV)
        {
            var gv = db.GIAOVIEN.Find(MAGV);
            if (gv == null) return HttpNotFound();

            try
            {
                db.GIAOVIEN.Remove(gv);
                db.SaveChanges();
                TempData["Message"] = "Xóa giáo viên thành công!";
            }
            catch (System.Data.Entity.Infrastructure.DbUpdateException)
            {
                TempData["Error"] = "Giáo viên đang được phân công hoặc có dữ liệu liên quan, không thể xóa.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi xóa: " + ex.Message;
            }
            return RedirectToAction("QuanLyGiaoVien");
        }

        // ==========================================================
        //                QUẢN LÝ HỌC SINH
        // ==========================================================
        public ActionResult QuanLyHocSinh(string searchMaHS, string searchTen, string searchGioiTinh, string searchTrangThai)
        {
            ViewBag.GioiTinhList = new SelectList(new[] { "Nam", "Nữ" });
            ViewBag.TrangThaiList = new SelectList(new[] { "Đang học", "Bảo lưu", "Thôi học", "Chuyển trường" });

            ViewBag.CurrentFilterMa = searchMaHS;
            ViewBag.CurrentFilterTen = searchTen;
            ViewBag.CurrentFilterGioiTinh = searchGioiTinh;
            ViewBag.CurrentFilterTrangThai = searchTrangThai;

            var query = db.HOCSINH.AsQueryable();

            if (!string.IsNullOrEmpty(searchMaHS)) query = query.Where(h => h.MAHS.Contains(searchMaHS));
            if (!string.IsNullOrEmpty(searchTen)) query = query.Where(h => h.HO.Contains(searchTen) || h.TEN.Contains(searchTen));
            if (!string.IsNullOrEmpty(searchGioiTinh)) query = query.Where(h => h.GIOITINH == searchGioiTinh);
            if (!string.IsNullOrEmpty(searchTrangThai)) query = query.Where(h => h.TRANGTHAI == searchTrangThai);

            return View(query.OrderBy(h => h.TEN).ToList());
        }

        public ActionResult ThemHocSinh()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemHocSinh(HOCSINH hs)
        {
            if (ModelState.IsValid)
            {
                if (db.HOCSINH.Any(x => x.MAHS == hs.MAHS))
                {
                    ModelState.AddModelError("MAHS", "Mã học sinh này đã tồn tại.");
                    return View(hs);
                }
                try
                {
                    db.HOCSINH.Add(hs);
                    db.SaveChanges();
                    TempData["Message"] = "Thêm học sinh thành công!";
                    return RedirectToAction("QuanLyHocSinh");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi hệ thống: " + ex.Message);
                }
            }
            return View(hs);
        }

        public ActionResult SuaHocSinh(string id)
        {
            if (string.IsNullOrEmpty(id)) return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            var hs = db.HOCSINH.Find(id);
            if (hs == null) return HttpNotFound();
            return View(hs);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaHocSinh(HOCSINH hs)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    db.Entry(hs).State = EntityState.Modified;
                    db.SaveChanges();
                    TempData["Message"] = "Cập nhật học sinh thành công!";
                    return RedirectToAction("QuanLyHocSinh");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi cập nhật: " + ex.Message);
                }
            }
            return View(hs);
        }

        public ActionResult XoaHocSinh(string id)
        {
            var hs = db.HOCSINH.Find(id);
            if (hs == null) return HttpNotFound();
            return View(hs);
        }

        [HttpPost, ActionName("XoaHocSinh")]
        [ValidateAntiForgeryToken]
        public ActionResult XacNhanXoaHocSinh(string MAHS)
        {
            var hs = db.HOCSINH.Find(MAHS);
            if (hs == null) return HttpNotFound();

            try
            {
                db.HOCSINH.Remove(hs);
                db.SaveChanges();
                TempData["Message"] = "Xóa học sinh thành công!";
            }
            catch (System.Data.Entity.Infrastructure.DbUpdateException)
            {
                TempData["Error"] = "Học sinh này đã có bảng điểm hoặc thông tin khác, không thể xóa.";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi xóa: " + ex.Message;
            }
            return RedirectToAction("QuanLyHocSinh");
        }

        // =========================================================
        //                QUẢN LÝ MÔN HỌC
        // =========================================================
        public ActionResult QuanLyMonHoc(string searchMaMH, string searchTenMH)
        {
            ViewBag.CurrentFilterMa = searchMaMH;
            ViewBag.CurrentFilterTen = searchTenMH;

            var dsMH = db.MONHOC.AsQueryable();

            if (!string.IsNullOrEmpty(searchMaMH)) dsMH = dsMH.Where(mh => mh.MAMH.Contains(searchMaMH));
            if (!string.IsNullOrEmpty(searchTenMH)) dsMH = dsMH.Where(mh => mh.TENMH.Contains(searchTenMH));

            return View(dsMH.OrderBy(m => m.TENMH).ToList());
        }

        public ActionResult ThemMonHoc()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemMonHoc(MONHOC mh)
        {
            if (ModelState.IsValid)
            {
                if (db.MONHOC.Any(x => x.MAMH == mh.MAMH))
                {
                    ModelState.AddModelError("MAMH", "Mã môn học này đã tồn tại.");
                    return View(mh);
                }
                if (db.MONHOC.Any(x => x.TENMH == mh.TENMH))
                {
                    ModelState.AddModelError("TENMH", "Tên môn học này đã tồn tại.");
                    return View(mh);
                }
                try
                {
                    db.MONHOC.Add(mh);
                    db.SaveChanges();
                    TempData["Message"] = "Thêm môn học thành công!";
                    return RedirectToAction("QuanLyMonHoc");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi hệ thống: " + ex.Message);
                }
            }
            return View(mh);
        }

        public ActionResult SuaMonHoc(string id)
        {
            if (string.IsNullOrEmpty(id)) return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            var mh = db.MONHOC.Find(id);
            if (mh == null) return HttpNotFound();
            return View(mh);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaMonHoc(MONHOC mh)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    db.Entry(mh).State = EntityState.Modified;
                    db.SaveChanges();
                    TempData["Message"] = "Cập nhật môn học thành công!";
                    return RedirectToAction("QuanLyMonHoc");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi cập nhật: " + ex.Message);
                }
            }
            return View(mh);
        }

        public ActionResult XoaMonHoc(string id)
        {
            var mh = db.MONHOC.Find(id);
            if (mh == null) return HttpNotFound();
            return View(mh);
        }

        [HttpPost, ActionName("XoaMonHoc")]
        [ValidateAntiForgeryToken]
        public ActionResult XoaMonHocConfirmed(string id)
        {
            var mh = db.MONHOC.Find(id);
            if (mh == null) return HttpNotFound();

            try
            {
                bool coDiem = db.DIEM.Any(d => d.MAMH == id);
                bool coTKB = db.THOIKHOABIEU.Any(t => t.MAMH == id);
                bool coPhanCong = db.PHANCONG.Any(p => p.MAMH == id);

                if (coDiem) TempData["Error"] = "Môn học này đã có điểm số, không thể xóa!";
                else if (coTKB) TempData["Error"] = "Môn học này đang có trong thời khóa biểu, không thể xóa!";
                else if (coPhanCong) TempData["Error"] = "Môn học này đang được phân công giảng dạy, không thể xóa!";
                else
                {
                    db.MONHOC.Remove(mh);
                    db.SaveChanges();
                    TempData["Message"] = "Xóa môn học thành công!";
                }
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi hệ thống: " + ex.Message;
            }
            return RedirectToAction("QuanLyMonHoc");
        }

        // ==========================================================
        //                QUẢN LÝ LỚP HỌC
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

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult XoaLop(string id)
        {
            try
            {
                LOP lop = db.LOP.Find(id);
                if (lop != null)
                {
                    bool coHocSinh = db.HOCSINH_NAMHOC.Any(hs => hs.MALOP == id);
                    bool coTKB = db.THOIKHOABIEU.Any(t => t.MALOP == id);
                    bool coPhanCong = db.PHANCONG.Any(pc => pc.MALOP == id);

                    if (coHocSinh) TempData["ErrorMessage"] = "Không thể xóa: Lớp này đang có học sinh theo học!";
                    else if (coTKB) TempData["ErrorMessage"] = "Không thể xóa: Lớp này đã được xếp thời khóa biểu!";
                    else if (coPhanCong) TempData["ErrorMessage"] = "Không thể xóa: Lớp này đã được phân công giáo viên giảng dạy!";
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
                TempData["ErrorMessage"] = "Lỗi hệ thống khi xóa: " + ex.Message;
            }
            return RedirectToAction("QuanLyLop");
        }

        // ==========================================================
        //                QUẢN LÝ TÀI KHOẢN
        // ==========================================================
        public ActionResult QuanLyTaiKhoan(string searchTenDN, string searchLoai, string searchTinhTrang)
        {
            ViewBag.LoaiList = new SelectList(new[] { "Admin", "GV", "HS" });
            ViewBag.TinhTrangList = new SelectList(new[] { "Hoạt động", "Khóa", "Tạm khóa" });

            ViewBag.CurrentFilterTen = searchTenDN;
            ViewBag.CurrentFilterLoai = searchLoai;
            ViewBag.CurrentFilterTinhTrang = searchTinhTrang;

            var dsTK = db.TAIKHOAN.Include(t => t.GIAOVIEN).Include(t => t.HOCSINH).AsQueryable();

            if (!string.IsNullOrEmpty(searchTenDN)) dsTK = dsTK.Where(tk => tk.USERNAME.Contains(searchTenDN));
            if (!string.IsNullOrEmpty(searchLoai)) dsTK = dsTK.Where(tk => tk.LOAI == searchLoai);
            if (!string.IsNullOrEmpty(searchTinhTrang)) dsTK = dsTK.Where(tk => tk.TINHTRANG == searchTinhTrang);

            return View(dsTK.OrderBy(t => t.USERNAME).ToList());
        }

        public ActionResult ThemTaiKhoan()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemTaiKhoan(TAIKHOAN tk)
        {
            if (ModelState.IsValid)
            {
                if (db.TAIKHOAN.Any(x => x.USERNAME == tk.USERNAME))
                {
                    ModelState.AddModelError("USERNAME", "Tên đăng nhập này đã tồn tại.");
                    return View(tk);
                }

                try
                {
                    if (tk.LOAI == "GV" && string.IsNullOrEmpty(tk.MAGV))
                    {
                        ModelState.AddModelError("MAGV", "Vui lòng nhập Mã Giáo Viên.");
                        return View(tk);
                    }
                    if (tk.LOAI == "HS" && string.IsNullOrEmpty(tk.MAHS))
                    {
                        ModelState.AddModelError("MAHS", "Vui lòng nhập Mã Học Sinh.");
                        return View(tk);
                    }

                    if (tk.NGAYTAO == null) tk.NGAYTAO = DateTime.Now;

                    db.TAIKHOAN.Add(tk);
                    db.SaveChanges();
                    TempData["Message"] = "Thêm tài khoản thành công!";
                    return RedirectToAction("QuanLyTaiKhoan");
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi hệ thống: " + ex.Message);
                }
            }
            return View(tk);
        }

        public ActionResult SuaTaiKhoan(string id)
        {
            if (string.IsNullOrEmpty(id)) return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            var tk = db.TAIKHOAN.Find(id);
            if (tk == null) return HttpNotFound();
            return View(tk);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaTaiKhoan(TAIKHOAN tk)
        {
            if (string.IsNullOrEmpty(tk.PASSWORD))
            {
                ModelState.Remove("PASSWORD");
            }

            if (ModelState.IsValid)
            {
                try
                {
                    var existingTK = db.TAIKHOAN.Find(tk.USERNAME);
                    if (existingTK != null)
                    {
                        existingTK.LOAI = tk.LOAI;
                        existingTK.TINHTRANG = tk.TINHTRANG;
                        existingTK.MAGV = tk.MAGV;
                        existingTK.MAHS = tk.MAHS;

                        if (!string.IsNullOrEmpty(tk.PASSWORD))
                        {
                            existingTK.PASSWORD = tk.PASSWORD;
                        }

                        db.SaveChanges();
                        TempData["Message"] = "Cập nhật tài khoản thành công!";
                        return RedirectToAction("QuanLyTaiKhoan");
                    }
                    else
                    {
                        return HttpNotFound();
                    }
                }
                catch (Exception ex)
                {
                    ModelState.AddModelError("", "Lỗi cập nhật: " + ex.Message);
                }
            }
            return View(tk);
        }

        public ActionResult XoaTaiKhoan(string id)
        {
            var tk = db.TAIKHOAN.Find(id);
            if (tk == null) return HttpNotFound();
            return View(tk);
        }

        [HttpPost, ActionName("XoaTaiKhoan")]
        [ValidateAntiForgeryToken]
        public ActionResult XoaTaiKhoanConfirmed(string id)
        {
            var tk = db.TAIKHOAN.Find(id);
            if (tk == null) return HttpNotFound();

            try
            {
                db.TAIKHOAN.Remove(tk);
                db.SaveChanges();
                TempData["Message"] = "Xóa tài khoản thành công!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi xóa: " + ex.Message;
            }
            return RedirectToAction("QuanLyTaiKhoan");
        }

        // ==========================================================
        //                QUẢN LÝ THỜI KHÓA BIỂU
        // ==========================================================
        public ActionResult QuanLyTKB(string searchMaLop, string searchMaGV, string searchNamHoc, string searchHocKy)
        {
            ViewBag.LopList = new SelectList(db.LOP, "MALOP", "TENLOP");
            ViewBag.GVList = new SelectList(db.GIAOVIEN.Where(g => g.TRANGTHAI == "Đang làm"), "MAGV", "HOTEN");
            ViewBag.NamList = new SelectList(db.NAMHOC, "MANAM", "TENNAM");
            ViewBag.HKList = new SelectList(db.HOCKY, "MAHK", "TENHK");

            if (string.IsNullOrEmpty(searchNamHoc)) searchNamHoc = db.NAMHOC.OrderByDescending(n => n.NGAYKETTHUC).Select(n => n.MANAM).FirstOrDefault();
            if (string.IsNullOrEmpty(searchHocKy)) searchHocKy = "HK1";

            ViewBag.CurrentLop = searchMaLop;
            ViewBag.CurrentGV = searchMaGV;
            ViewBag.CurrentNam = searchNamHoc;
            ViewBag.CurrentHK = searchHocKy;

            var query = db.THOIKHOABIEU
                          .Include(t => t.LOP)
                          .Include(t => t.MONHOC)
                          .Include(t => t.GIAOVIEN)
                          .Include(t => t.PHONGHOC)
                          .Where(t => t.MANAM == searchNamHoc && t.MAHK == searchHocKy);

            if (!string.IsNullOrEmpty(searchMaLop)) query = query.Where(t => t.MALOP == searchMaLop);
            if (!string.IsNullOrEmpty(searchMaGV)) query = query.Where(t => t.MAGV == searchMaGV);

            return View(query.OrderBy(t => t.THU).ThenBy(t => t.TIET).ThenBy(t => t.MALOP).ToList());
        }

        public ActionResult ThemTKB()
        {
            PrepareViewBagTKB();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ThemTKB(THOIKHOABIEU tkb)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    db.Database.ExecuteSqlCommand("EXEC PROC_TKB_THEM @MALOP, @MAMH, @MAGV, @MANAM, @MAHK, @THU, @TIET, @MAPHONG",
                        new System.Data.SqlClient.SqlParameter("@MALOP", tkb.MALOP),
                        new System.Data.SqlClient.SqlParameter("@MAMH", tkb.MAMH),
                        new System.Data.SqlClient.SqlParameter("@MAGV", tkb.MAGV),
                        new System.Data.SqlClient.SqlParameter("@MANAM", tkb.MANAM),
                        new System.Data.SqlClient.SqlParameter("@MAHK", tkb.MAHK),
                        new System.Data.SqlClient.SqlParameter("@THU", tkb.THU),
                        new System.Data.SqlClient.SqlParameter("@TIET", tkb.TIET),
                        new System.Data.SqlClient.SqlParameter("@MAPHONG", tkb.MAPHONG));
                    TempData["Message"] = "Thêm thời khóa biểu thành công!";
                    return RedirectToAction("QuanLyTKB", new { searchNamHoc = tkb.MANAM, searchHocKy = tkb.MAHK, searchMaLop = tkb.MALOP });
                }
                catch (Exception ex)
                {
                    string errorMsg = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                    if (errorMsg.Contains("Lỗi:")) ModelState.AddModelError("", errorMsg.Substring(errorMsg.IndexOf("Lỗi:")));
                    else ModelState.AddModelError("", "Lỗi hệ thống: " + errorMsg);
                }
            }
            PrepareViewBagTKB(tkb.MALOP, tkb.MAMH, tkb.MAGV, tkb.MANAM, tkb.MAHK, tkb.MAPHONG);
            return View(tkb);
        }

        public ActionResult SuaTKB(string maLop, string maNam, string maHK, int thu, int tiet)
        {
            var tkb = db.THOIKHOABIEU.FirstOrDefault(t => t.MALOP == maLop && t.MANAM == maNam && t.MAHK == maHK && t.THU == thu && t.TIET == tiet);
            if (tkb == null) return HttpNotFound();
            PrepareViewBagTKB(tkb.MALOP, tkb.MAMH, tkb.MAGV, tkb.MANAM, tkb.MAHK, tkb.MAPHONG);
            return View(tkb);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult SuaTKB(THOIKHOABIEU tkb)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    db.Database.ExecuteSqlCommand("EXEC PROC_TKB_SUA @MALOP, @MANAM, @MAHK, @THU, @TIET, @NEWMAMH, @NEWMAGV, @NEWMAPHONG",
                        new System.Data.SqlClient.SqlParameter("@MALOP", tkb.MALOP),
                        new System.Data.SqlClient.SqlParameter("@MANAM", tkb.MANAM),
                        new System.Data.SqlClient.SqlParameter("@MAHK", tkb.MAHK),
                        new System.Data.SqlClient.SqlParameter("@THU", tkb.THU),
                        new System.Data.SqlClient.SqlParameter("@TIET", tkb.TIET),
                        new System.Data.SqlClient.SqlParameter("@NEWMAMH", tkb.MAMH),
                        new System.Data.SqlClient.SqlParameter("@NEWMAGV", tkb.MAGV),
                        new System.Data.SqlClient.SqlParameter("@NEWMAPHONG", tkb.MAPHONG));
                    TempData["Message"] = "Cập nhật thời khóa biểu thành công!";
                    return RedirectToAction("QuanLyTKB", new { searchNamHoc = tkb.MANAM, searchHocKy = tkb.MAHK, searchMaLop = tkb.MALOP });
                }
                catch (Exception ex)
                {
                    string errorMsg = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                    ModelState.AddModelError("", "Lỗi cập nhật: " + errorMsg);
                }
            }
            PrepareViewBagTKB(tkb.MALOP, tkb.MAMH, tkb.MAGV, tkb.MANAM, tkb.MAHK, tkb.MAPHONG);
            return View(tkb);
        }

        [HttpGet]
        public ActionResult XoaTKB(string maLop, string maNam, string maHK, int? thu, int? tiet)
        {
            if (string.IsNullOrEmpty(maLop) || string.IsNullOrEmpty(maNam) || string.IsNullOrEmpty(maHK) || thu == null || tiet == null)
            {
                return new HttpStatusCodeResult(System.Net.HttpStatusCode.BadRequest);
            }

            var tkb = db.THOIKHOABIEU
                        .Include(t => t.LOP)
                        .Include(t => t.MONHOC)
                        .Include(t => t.GIAOVIEN)
                        .Include(t => t.PHONGHOC)
                        .FirstOrDefault(t => t.MALOP == maLop && t.MANAM == maNam && t.MAHK == maHK && t.THU == thu && t.TIET == tiet);

            if (tkb == null) return HttpNotFound();

            return View(tkb);
        }

        [HttpPost, ActionName("XoaTKB")]
        [ValidateAntiForgeryToken]
        public ActionResult XoaTKBConfirmed(string maLop, string maNam, string maHK, int thu, int tiet)
        {
            try
            {
                db.Database.ExecuteSqlCommand(
                    "EXEC PROC_TKB_XOA @MALOP, @MANAM, @MAHK, @THU, @TIET",
                    new System.Data.SqlClient.SqlParameter("@MALOP", maLop),
                    new System.Data.SqlClient.SqlParameter("@MANAM", maNam),
                    new System.Data.SqlClient.SqlParameter("@MAHK", maHK),
                    new System.Data.SqlClient.SqlParameter("@THU", thu),
                    new System.Data.SqlClient.SqlParameter("@TIET", tiet)
                );
                TempData["Message"] = "Đã xóa tiết học thành công!";
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi xóa: " + ex.Message;
            }
            return RedirectToAction("QuanLyTKB", new { searchNamHoc = maNam, searchHocKy = maHK, searchMaLop = maLop });
        }

        // Helper cho Dropdown TKB
        private void PrepareViewBagTKB(string selectedLop = null, string selectedMH = null, string selectedGV = null, string selectedNam = null, string selectedHK = null, string selectedPhong = null)
        {
            ViewBag.MALOP = new SelectList(db.LOP, "MALOP", "TENLOP", selectedLop);
            ViewBag.MAMH = new SelectList(db.MONHOC, "MAMH", "TENMH", selectedMH);
            ViewBag.MAGV = new SelectList(db.GIAOVIEN.Where(g => g.TRANGTHAI == "Đang làm"), "MAGV", "HOTEN", selectedGV);
            ViewBag.MANAM = new SelectList(db.NAMHOC, "MANAM", "TENNAM", selectedNam);
            ViewBag.MAHK = new SelectList(db.HOCKY, "MAHK", "TENHK", selectedHK);
            ViewBag.MAPHONG = new SelectList(db.PHONGHOC.Where(p => p.TINHTRANG == "Hoạt động"), "MAPHONG", "TENPHONG", selectedPhong);

            ViewBag.THU = new SelectList(Enumerable.Range(2, 6).Select(x => new { Val = x, Txt = "Thứ " + x }), "Val", "Txt");
            ViewBag.TIET = new SelectList(Enumerable.Range(1, 10).Select(x => new { Val = x, Txt = "Tiết " + x }), "Val", "Txt");
        }
    }
}