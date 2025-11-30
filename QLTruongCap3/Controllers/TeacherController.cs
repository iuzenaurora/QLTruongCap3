using QLTruongCap3.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity.Core.Objects; // Để dùng ObjectParameter
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web.Mvc;
using System.Web.Routing;

namespace QLTruongC3.Controllers
{
    [Authorize(Roles = "GV")]
    public class TeacherController : Controller
    {
        private QLTRUONGC3Entities db = new QLTRUONGC3Entities();

        // --- FIX LỖI: Ép buộc hệ thống dùng dấu chấm (.) cho số thập phân ---
        // Điều này đảm bảo khi trình duyệt gửi "8.5", Server sẽ hiểu là 8.5 chứ không phải lỗi
        protected override void Initialize(RequestContext requestContext)
        {
            base.Initialize(requestContext);
            CultureInfo ci = new CultureInfo("en-US");
            Thread.CurrentThread.CurrentCulture = ci;
            Thread.CurrentThread.CurrentUICulture = ci;
        }

        private string GetCurrentMaGV()
        {
            var username = User.Identity.Name;
            var user = db.TAIKHOAN.FirstOrDefault(u => u.USERNAME == username);
            return user?.MAGV;
        }

        public ActionResult Index()
        {
            var maGV = GetCurrentMaGV();
            var gv = db.GIAOVIEN.FirstOrDefault(g => g.MAGV == maGV);
            return View(gv);
        }

        // --- NHẬP ĐIỂM ---
        [HttpGet]
        public ActionResult NhapDiem(string maLop, string maMH, string maHK, string maNam)
        {
            string maGV = GetCurrentMaGV();

            // 1. Lấy danh sách lớp: Bao gồm lớp được Phân công dạy VÀ lớp Chủ nhiệm
            // Lớp dạy
            var listLopDay = db.PHANCONG.Where(p => p.MAGV == maGV).Select(p => p.LOP).ToList();
            // Lớp chủ nhiệm
            var listLopCN = db.LOP.Where(l => l.MAGVCN == maGV).ToList();

            // Gộp lại và loại bỏ trùng lặp (dùng Union và Distinct)
            var listLop = listLopDay.Union(listLopCN).Distinct().OrderBy(l => l.TENLOP).ToList();

            ViewBag.MaLop = new SelectList(listLop, "MALOP", "TENLOP", maLop);

            // 2. Xử lý logic hiển thị Môn học và Quyền hạn
            bool isReadOnly = true; // Mặc định là chỉ xem

            // Nếu chưa chọn lớp, load danh sách môn rỗng hoặc mặc định
            if (string.IsNullOrEmpty(maLop))
            {
                ViewBag.MaMH = new SelectList(new List<MONHOC>(), "MAMH", "TENMH");
            }
            else
            {
                // Kiểm tra xem GV có phải GVCN của lớp đang chọn không?
                bool isGVCN = listLopCN.Any(l => l.MALOP == maLop);

                if (isGVCN)
                {
                    // Nếu là GVCN: Được xem TẤT CẢ môn học của hệ thống (hoặc môn học của khối lớp đó)
                    var allMon = db.MONHOC.OrderBy(m => m.TENMH).ToList();
                    ViewBag.MaMH = new SelectList(allMon, "MAMH", "TENMH", maMH);
                }
                else
                {
                    // Nếu KHÔNG phải GVCN: Chỉ hiện môn mình được phân công dạy
                    var monDuocDay = db.PHANCONG.Where(p => p.MAGV == maGV && p.MALOP == maLop)
                                                .Select(p => p.MONHOC).Distinct().OrderBy(m => m.TENMH).ToList();
                    ViewBag.MaMH = new SelectList(monDuocDay, "MAMH", "TENMH", maMH);
                }

                // 3. Xác định quyền Ghi (Editable)
                if (!string.IsNullOrEmpty(maMH))
                {
                    bool isPhanCong = db.PHANCONG.Any(p => p.MAGV == maGV && p.MALOP == maLop && p.MAMH == maMH);
                    if (isPhanCong)
                    {
                        isReadOnly = false; // Được phép nhập/sửa
                    }
                }
            }

            ViewBag.IsReadOnly = isReadOnly;
            ViewBag.MaHK = new SelectList(db.HOCKY, "MAHK", "TENHK", maHK);
            ViewBag.MaNam = new SelectList(db.NAMHOC, "MANAM", "TENNAM", maNam);

            // 4. Lấy dữ liệu học sinh và điểm
            if (!string.IsNullOrEmpty(maLop) && !string.IsNullOrEmpty(maMH) && !string.IsNullOrEmpty(maNam) && !string.IsNullOrEmpty(maHK))
            {
                var data = db.sp_GetDanhSachHocSinhVaDiem(maLop, maMH, maNam, maHK).ToList();
                return View(data);
            }

            return View(new List<sp_GetDanhSachHocSinhVaDiem_Result>());
        }

        [HttpPost]
        public ActionResult LuuDiem(List<sp_GetDanhSachHocSinhVaDiem_Result> listDiem, string maMH, string maHK, string maNam, string maLop)
        {
            string maGV = GetCurrentMaGV();

            // KIỂM TRA BẢO MẬT
            bool isPhanCong = db.PHANCONG.Any(p => p.MAGV == maGV && p.MALOP == maLop && p.MAMH == maMH);

            if (!isPhanCong)
            {
                TempData["Error"] = "Bạn không có quyền sửa điểm môn học này (Chỉ xem)!";
                return RedirectToAction("NhapDiem", new { maLop, maMH, maHK, maNam });
            }

            var outRes = new ObjectParameter("Result", typeof(int));
            var outMsg = new ObjectParameter("Message", typeof(string));

            if (listDiem != null)
            {
                foreach (var hs in listDiem)
                {
                    // Gọi Proc cho từng cột điểm
                    if (hs.DIEMMIENG.HasValue) db.sp_NhapDiem(hs.MAHS, maMH, maHK, maNam, "DM", hs.DIEMMIENG, null, outRes, outMsg);
                    if (hs.DIEM15PHUT.HasValue) db.sp_NhapDiem(hs.MAHS, maMH, maHK, maNam, "D15", hs.DIEM15PHUT, null, outRes, outMsg);
                    if (hs.DIEM1TIET.HasValue) db.sp_NhapDiem(hs.MAHS, maMH, maHK, maNam, "D1T", hs.DIEM1TIET, null, outRes, outMsg);
                    if (hs.DIEMTHI.HasValue) db.sp_NhapDiem(hs.MAHS, maMH, maHK, maNam, "DTH", hs.DIEMTHI, null, outRes, outMsg);
                }
                TempData["Success"] = "Đã lưu điểm thành công!";
            }
            return RedirectToAction("NhapDiem", new { maLop, maMH, maHK, maNam });
        }

        // --- THỜI KHÓA BIỂU ---
        public ActionResult ThoiKhoaBieu()
        {
            string maGV = GetCurrentMaGV();
            var tkb = db.THOIKHOABIEU.Where(t => t.MAGV == maGV).OrderBy(t => t.THU).ThenBy(t => t.TIET).ToList();
            return View(tkb);
        }

        // --- ĐIỂM DANH ---
        public ActionResult DiemDanh()
        {
            string maGV = GetCurrentMaGV();
            var lopCN = db.LOP.FirstOrDefault(l => l.MAGVCN == maGV);
            if (lopCN == null)
            {
                ViewBag.Error = "Bạn không chủ nhiệm lớp nào!";
                return View(new List<HOCSINH>());
            }
            var namHienTai = "2024-2025";
            var listHS = db.HOCSINH_NAMHOC.Where(h => h.MALOP == lopCN.MALOP && h.MANAM == namHienTai)
                            .Select(h => h.HOCSINH).OrderBy(h => h.TEN).ToList();
            ViewBag.TenLop = lopCN.TENLOP;
            return View(listHS);
        }
    }
}