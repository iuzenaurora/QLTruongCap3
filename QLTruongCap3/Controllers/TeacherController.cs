using QLTruongCap3.Models;
using System;
using System.Collections.Generic;
using System.Data.Entity.Core.Objects; // Để dùng ObjectParameter
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Web.Mvc;
using System.Web.Routing;
using System.Data.Entity;

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

            var lopCN = db.LOP.FirstOrDefault(l => l.MAGVCN == maGV);
            ViewBag.LopCN = lopCN != null ? lopCN.TENLOP : null;

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
        //public ActionResult ThoiKhoaBieu()
        //{
        //    string maGV = GetCurrentMaGV();
        //    var tkb = db.THOIKHOABIEU.Where(t => t.MAGV == maGV).OrderBy(t => t.THU).ThenBy(t => t.TIET).ToList();
        //    return View(tkb);
        //}
        [HttpGet]
        public ActionResult ThoiKhoaBieu(string maNam, string maHK, DateTime? ngayXem)
        {
            string maGV = GetCurrentMaGV();

            // 1. Xử lý giá trị mặc định cho Dropdown
            if (string.IsNullOrEmpty(maNam))
            {
                var namMoiNhat = db.NAMHOC.OrderByDescending(n => n.TENNAM).FirstOrDefault();
                maNam = namMoiNhat != null ? namMoiNhat.MANAM : "2024-2025";
            }
            if (string.IsNullOrEmpty(maHK)) maHK = "HK1";

            // 2. Truy vấn cơ bản (Có Include để lấy Tên Môn, Tên Lớp, Tên Phòng)
            var query = db.THOIKHOABIEU
                          .Include(t => t.MONHOC)
                          .Include(t => t.LOP)
                          .Include(t => t.PHONGHOC)
                          .Where(t => t.MAGV == maGV && t.MANAM == maNam && t.MAHK == maHK);

            // 3. Logic lọc theo NGÀY (Nếu người dùng chọn ngày)
            if (ngayXem.HasValue)
            {
                // Quy đổi ngày dương lịch sang Thứ trong tuần (T2=2, T3=3..., CN=8 hoặc 1)
                // Trong C#: Sunday=0, Monday=1, Tuesday=2...
                // Trong DB của bạn: Thứ 2 là số 2, Thứ 3 là số 3.
                // => Công thức: (int)DayOfWeek + 1
                int thuHienTai = (int)ngayXem.Value.DayOfWeek + 1;

                // Xử lý riêng Chủ Nhật (nếu C# trả về 0 thì đổi thành 8 hoặc bỏ qua tùy quy ước DB)
                if (thuHienTai == 1) thuHienTai = 8;

                query = query.Where(t => t.THU == thuHienTai);

                ViewBag.NgayXem = ngayXem.Value.ToString("yyyy-MM-dd");
                ViewBag.ThuHienTai = "Thứ " + thuHienTai;
            }
            else
            {
                ViewBag.ThuHienTai = "Cả tuần";
            }

            // 4. Chuẩn bị dữ liệu cho View
            ViewBag.MaNam = new SelectList(db.NAMHOC.OrderByDescending(n => n.TENNAM), "MANAM", "TENNAM", maNam);
            ViewBag.MaHK = new SelectList(db.HOCKY, "MAHK", "TENHK", maHK);

            // Sắp xếp: Thứ tăng dần -> Tiết tăng dần
            var tkb = query.OrderBy(t => t.THU).ThenBy(t => t.TIET).ToList();

            return View(tkb);
        }

        // --- ĐIỂM DANH ---
        [HttpGet]
        public ActionResult DiemDanh(string maNam, string maHK)
        {
            string maGV = GetCurrentMaGV();
            // Lấy lớp chủ nhiệm của GV
            var lopCN = db.LOP.FirstOrDefault(l => l.MAGVCN == maGV);

            if (lopCN == null)
            {
                ViewBag.Error = "Bạn không chủ nhiệm lớp nào!";
                return View(new List<HOCSINH>());
            }

            // --- XỬ LÝ DROPDOWN ---
            // 1.1. Nếu chưa chọn (lần đầu vào trang), lấy giá trị mặc định (VD: Năm mới nhất, HK1)
            if (string.IsNullOrEmpty(maNam))
            {
                var namMoiNhat = db.NAMHOC.OrderByDescending(n => n.TENNAM).FirstOrDefault();
                maNam = namMoiNhat != null ? namMoiNhat.MANAM : "2024-2025";
            }
            if (string.IsNullOrEmpty(maHK)) maHK = "HK1";

            // 1.2. Tạo danh sách đổ vào Dropdown
            ViewBag.MaNam = new SelectList(db.NAMHOC.OrderByDescending(n => n.TENNAM), "MANAM", "TENNAM", maNam);
            ViewBag.MaHK = new SelectList(db.HOCKY, "MAHK", "TENHK", maHK);

            // 1.3. Lưu giá trị đang chọn để View sử dụng lại (quan trọng cho Script reload)
            ViewBag.SelectedNam = maNam;
            ViewBag.SelectedHK = maHK;
            ViewBag.TenLop = lopCN.TENLOP;

            // --- LỌC DANH SÁCH HỌC SINH THEO NĂM HỌC ĐƯỢC CHỌN ---
            // Chỉ lấy học sinh phân vào lớp đó trong năm học đó
            var listHS = db.HOCSINH_NAMHOC
                            .Where(h => h.MALOP == lopCN.MALOP && h.MANAM == maNam)
                            .Select(h => h.HOCSINH)
                            .OrderBy(h => h.TEN)
                            .ToList();

            return View(listHS);
        }


        [HttpPost]
        public ActionResult LuuDiemDanh(List<DiemDanhItem> listDD, DateTime ngayDD, int tiet, string maNam, string maHK)
        {
            // Kiểm tra danh sách trống
            if (listDD == null || listDD.Count == 0)
            {
                TempData["Message"] = "Không có dữ liệu học sinh để lưu!";
                // Quay lại trang cũ, giữ nguyên tham số năm/kỳ
                return RedirectToAction("DiemDanh", new { maNam = maNam, maHK = maHK });
            }

            using (var transaction = db.Database.BeginTransaction())
            {
                try
                {
                    foreach (var item in listDD)
                    {
                        // Gọi Stored Procedure: SP_DiemDanh_CaNhan
                        // SQL sẽ tự tìm GV và Môn học dựa vào TKB của (Lớp + Năm + Kỳ + Ngày + Tiết)
                        string sql = "EXEC SP_DiemDanh_CaNhan @MAHS, @MANAM, @MAHK, @NGAY, @TIET, @TRANGTHAI, @LYDOVANG";

                        db.Database.ExecuteSqlCommand(sql,
                            new System.Data.SqlClient.SqlParameter("@MAHS", item.MAHS),
                            new System.Data.SqlClient.SqlParameter("@MANAM", maNam), // Lấy từ Dropdown form gửi về
                            new System.Data.SqlClient.SqlParameter("@MAHK", maHK),   // Lấy từ Dropdown form gửi về
                            new System.Data.SqlClient.SqlParameter("@NGAY", ngayDD),
                            new System.Data.SqlClient.SqlParameter("@TIET", tiet),
                            new System.Data.SqlClient.SqlParameter("@TRANGTHAI", item.TRANGTHAI),
                            new System.Data.SqlClient.SqlParameter("@LYDOVANG", item.GHICHU ?? "") // Nếu null thì truyền chuỗi rỗng
                        );
                    }

                    db.SaveChanges();
                    transaction.Commit();
                    TempData["Message"] = $"Đã lưu điểm danh thành công: {ngayDD:dd/MM/yyyy} - Tiết {tiet}";
                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    string err = ex.InnerException != null ? ex.InnerException.Message : ex.Message;

                    // Bắt lỗi logic từ SQL (Ví dụ: Không có TKB)
                    if (err.Contains("50003") || err.Contains("Không tìm thấy tiết học"))
                    {
                        ViewBag.Error = $"Lỗi: Lớp không có lịch học vào Tiết {tiet}, ngày {ngayDD:dd/MM/yyyy} (trong TKB {maNam}-{maHK}).";
                    }
                    else
                    {
                        ViewBag.Error = "Lỗi hệ thống: " + err;
                    }

                    // Load lại trang kèm thông báo lỗi (Gọi hàm GET để nạp lại Dropdown)
                    return DiemDanh(maNam, maHK);
                }
            }

            // Thành công -> Load lại trang đó
            return RedirectToAction("DiemDanh", new { maNam = maNam, maHK = maHK });
        }
    }
}