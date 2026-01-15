-- =============================================
-- PHẦN 1: TẠO DATABASE VÀ FILEGROUPS
-- =============================================

CREATE DATABASE QL_TRUONGC3
ON PRIMARY
(
    NAME = QLTruongC3_Primary,
    FILENAME = 'C:\HQT CSDL\QLTruongC3_Primary.mdf',
    SIZE = 30MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
),
FILEGROUP G_HS
(
    NAME = QLTruongC3_HS,
    FILENAME = 'C:\HQT CSDL\QLTruongC3_HS.ndf',
    SIZE = 30MB,
    FILEGROWTH = 5MB
),
FILEGROUP G_GV
(
    NAME = QLTruongC3_GV,
    FILENAME = 'C:\HQT CSDL\QLTruongC3_GV.ndf',
    SIZE = 30MB,
    FILEGROWTH = 5MB
),
FILEGROUP G_SYS
(
    NAME = QLTruongC3_SYS,
    FILENAME = 'C:\HQT CSDL\QLTruongC3_SYS.ndf',
    SIZE = 20MB,
    FILEGROWTH = 5MB
)
LOG ON
(
    NAME = QLTruongC3_Log,
    FILENAME = 'C:\HQT CSDL\QLTruongC3_Log.ldf',
    SIZE = 15MB,
    FILEGROWTH = 5MB
)
GO

USE QL_TRUONGC3
GO

-- =============================================
-- PHẦN 2: TẠO CÁC BẢNG
-- =============================================

-- 1. KHOI
CREATE TABLE KHOI (
    MAKHOI CHAR(3) NOT NULL,
    TENKHOI NVARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT PK_KHOI PRIMARY KEY (MAKHOI)
) ON G_HS
GO

-- Thêm Khối
INSERT INTO KHOI (MAKHOI, TENKHOI) VALUES
('K10', N'Khối 10'),
('K11', N'Khối 11'),
('K12', N'Khối 12');
GO

-- 2. GIAOVIEN
CREATE TABLE GIAOVIEN (
    MAGV CHAR(5) NOT NULL,
    HOTEN NVARCHAR(50) NOT NULL,
    NGAYSINH DATE CHECK (NGAYSINH < GETDATE()),
    GIOITINH NVARCHAR(3) CHECK (GIOITINH IN (N'Nam',N'Nữ')),
    DIENTHOAI VARCHAR(12) UNIQUE,
    EMAIL VARCHAR(50) UNIQUE,
    DIACHI NVARCHAR(100),
    CCCD VARCHAR(12) UNIQUE,
    CHUYENMON NVARCHAR(50),
    TRINHDOHOCVAN NVARCHAR(30),
    NGAYVAOLAM DATE DEFAULT GETDATE(),
    TRANGTHAI NVARCHAR(20) DEFAULT N'Đang làm' CHECK (TRANGTHAI IN (N'Đang làm',N'Nghỉ việc',N'Tạm nghỉ')),
    NOISINH NVARCHAR(50),
    CONSTRAINT PK_GIAOVIEN PRIMARY KEY (MAGV)
) ON G_GV
GO

-- 3. LOP
CREATE TABLE LOP (
    MALOP CHAR(5) NOT NULL,
    TENLOP NVARCHAR(30) NOT NULL,
    MAKHOI CHAR(3) NOT NULL,
    SISO INT DEFAULT 0 CHECK (SISO >= 0),
    MAGVCN CHAR(5) NULL,
    CONSTRAINT PK_LOP PRIMARY KEY (MALOP),
    CONSTRAINT FK_LOP_KHOI FOREIGN KEY (MAKHOI) REFERENCES KHOI(MAKHOI),
    CONSTRAINT FK_LOP_GVCN FOREIGN KEY (MAGVCN) REFERENCES GIAOVIEN(MAGV)
) ON G_HS
GO

-- 4. HOCSINH
CREATE TABLE HOCSINH (
    MAHS CHAR(6) NOT NULL,
    HO NVARCHAR(30) NOT NULL,
    TEN NVARCHAR(20) NOT NULL,
    NGAYSINH DATE CHECK (NGAYSINH < GETDATE()),
    GIOITINH NVARCHAR(3) CHECK (GIOITINH IN (N'Nam',N'Nữ')),
    DIACHI NVARCHAR(100),
    DIENTHOAI VARCHAR(12),
    EMAIL VARCHAR(50),
    DANTOC NVARCHAR(30) DEFAULT N'Kinh',
    TONGIAO NVARCHAR(30),
    NOISINH NVARCHAR(50),
    TRANGTHAI NVARCHAR(20) DEFAULT N'Đang học' CHECK (TRANGTHAI IN (N'Đang học',N'Bảo lưu',N'Thôi học',N'Chuyển trường')),
    NGAYNHAPHOC DATE DEFAULT GETDATE(),
    CONSTRAINT PK_HOCSINH PRIMARY KEY (MAHS)
) ON G_HS
GO

-- 5. MONHOC
CREATE TABLE MONHOC (
    MAMH CHAR(6) NOT NULL,
    TENMH NVARCHAR(50) NOT NULL UNIQUE,
    HESO INT DEFAULT 1 CHECK (HESO BETWEEN 1 AND 3),
    SOTIET INT CHECK (SOTIET > 0),
    CONSTRAINT PK_MONHOC PRIMARY KEY (MAMH)
) ON G_GV
GO

-- 6. NAMHOC
CREATE TABLE NAMHOC (
    MANAM CHAR(9) NOT NULL,
    TENNAM NVARCHAR(30) NOT NULL UNIQUE,
    NGAYBATDAU DATE,
    NGAYKETTHUC DATE,
    CONSTRAINT PK_NAMHOC PRIMARY KEY (MANAM),
    CONSTRAINT CHK_NAMHOC_DATE CHECK (NGAYKETTHUC > NGAYBATDAU)
) ON G_HS
GO

-- 7. HOCKY
CREATE TABLE HOCKY (
    MAHK CHAR(3) NOT NULL,
    TENHK NVARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT PK_HOCKY PRIMARY KEY (MAHK)
) ON G_HS
GO

-- Thêm Học kỳ
INSERT INTO HOCKY (MAHK, TENHK) VALUES
('HK1', N'Học kỳ 1'),
('HK2', N'Học kỳ 2');
GO


-- 8. HOCSINH_NAMHOC
CREATE TABLE HOCSINH_NAMHOC (
    MAHS CHAR(6) NOT NULL,
    MANAM CHAR(9) NOT NULL,
    MALOP CHAR(5) NOT NULL,
    CONSTRAINT PK_HSN PRIMARY KEY (MAHS, MANAM),
    CONSTRAINT FK_HSN_HS FOREIGN KEY (MAHS) REFERENCES HOCSINH(MAHS) ON DELETE CASCADE,
    CONSTRAINT FK_HSN_NAM FOREIGN KEY (MANAM) REFERENCES NAMHOC(MANAM),
    CONSTRAINT FK_HSN_LOP FOREIGN KEY (MALOP) REFERENCES LOP(MALOP)
) ON G_HS
GO

-- 9. PHUHUYNH
CREATE TABLE PHUHUYNH (
    MAHS CHAR(6) NOT NULL,
    HOTEN NVARCHAR(50) NOT NULL,
    QUANHE NVARCHAR(20) CHECK (QUANHE IN (N'Bố',N'Mẹ',N'Anh',N'Chị',N'Ông',N'Bà',N'Khác')),
    NAMSINH INT,
    DIENTHOAI VARCHAR(12) NOT NULL,
    EMAIL VARCHAR(50),
    NGHENGHIEP NVARCHAR(50),
    NOILAM NVARCHAR(100),
    CONSTRAINT PK_PHUHUYNH PRIMARY KEY (MAHS, QUANHE),
    CONSTRAINT FK_PH_HS FOREIGN KEY (MAHS) REFERENCES HOCSINH(MAHS) ON DELETE CASCADE
) ON G_HS
GO

-- 10. LOAIDIEM
CREATE TABLE LOAIDIEM (
    MALOAIDIEM CHAR(3) NOT NULL,
    TENLOAIDIEM NVARCHAR(30) NOT NULL UNIQUE,
    HESODIEM INT DEFAULT 1 CHECK (HESODIEM > 0),
    CONSTRAINT PK_LOAIDIEM PRIMARY KEY (MALOAIDIEM)
) ON G_HS
GO

-- Thêm Loại điểm
INSERT INTO LOAIDIEM (MALOAIDIEM, TENLOAIDIEM, HESODIEM) VALUES
('DM', N'Điểm miệng', 1),
('D15', N'Điểm 15 phút', 1),
('D1T', N'Điểm 1 tiết', 2),
('DTH', N'Điểm thi', 3);
GO

-- 11. DIEM
CREATE TABLE DIEM (
    MAHS CHAR(6) NOT NULL,
    MAMH CHAR(6) NOT NULL,
    MAHK CHAR(3) NOT NULL,
    MANAM CHAR(9) NOT NULL,
    MALOAIDIEM CHAR(3) NOT NULL,
    DIEM DECIMAL(4,2) CHECK (DIEM BETWEEN 0 AND 10),
    NGAYNHAP DATE DEFAULT GETDATE(),
    GHICHU NVARCHAR(200),
    CONSTRAINT PK_DIEM PRIMARY KEY (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM),
    CONSTRAINT FK_DIEM_HS FOREIGN KEY (MAHS) REFERENCES HOCSINH(MAHS),
    CONSTRAINT FK_DIEM_MH FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH),
    CONSTRAINT FK_DIEM_HK FOREIGN KEY (MAHK) REFERENCES HOCKY(MAHK),
    CONSTRAINT FK_DIEM_NAM FOREIGN KEY (MANAM) REFERENCES NAMHOC(MANAM),
    CONSTRAINT FK_DIEM_LOAI FOREIGN KEY (MALOAIDIEM) REFERENCES LOAIDIEM(MALOAIDIEM)
) ON G_HS
GO

-- 12. DIEMDANH
CREATE TABLE DIEMDANH (
    MAHS CHAR(6) NOT NULL,
    MAGV CHAR(5) NOT NULL,
    MAMH CHAR(6) NOT NULL,
    MANAM CHAR(9) NOT NULL,
    MAHK CHAR(3) NOT NULL,
    NGAYDIEMDANH DATE NOT NULL,
    TIET INT CHECK (TIET BETWEEN 1 AND 10),
    TRANGTHAI NVARCHAR(30) DEFAULT N'Có mặt' CHECK (TRANGTHAI IN (N'Có mặt',N'Vắng có phép',N'Vắng không phép',N'Đi muộn',N'Về sớm')),
    LYDOVANG NVARCHAR(200),
    CONSTRAINT PK_DIEMDANH PRIMARY KEY (MAHS, NGAYDIEMDANH, TIET, MANAM, MAHK),
    CONSTRAINT FK_DD_HS FOREIGN KEY (MAHS) REFERENCES HOCSINH(MAHS),
    CONSTRAINT FK_DD_GV FOREIGN KEY (MAGV) REFERENCES GIAOVIEN(MAGV),
    CONSTRAINT FK_DD_MH FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH),
    CONSTRAINT FK_DD_NAM FOREIGN KEY (MANAM) REFERENCES NAMHOC(MANAM),
    CONSTRAINT FK_DD_HK FOREIGN KEY (MAHK) REFERENCES HOCKY(MAHK)
) ON G_HS
GO

-- 13. PHONGHOC
CREATE TABLE PHONGHOC (
    MAPHONG CHAR(5) NOT NULL,
    TENPHONG NVARCHAR(20) NOT NULL,
    LOAIPHONG NVARCHAR(30),
    SUCCHUA INT CHECK (SUCCHUA > 0),
    VITRI NVARCHAR(50),
    TINHTRANG NVARCHAR(20) DEFAULT N'Hoạt động' CHECK (TINHTRANG IN (N'Hoạt động',N'Bảo trì',N'Không dùng')),
    CONSTRAINT PK_PHONGHOC PRIMARY KEY (MAPHONG)
) ON G_GV
GO

-- 14. PHANCONG
CREATE TABLE PHANCONG (
    MAGV CHAR(5) NOT NULL,
    MALOP CHAR(5) NOT NULL,
    MAMH CHAR(6) NOT NULL,
    MAHK CHAR(3) NOT NULL,
    MANAM CHAR(9) NOT NULL,
    CONSTRAINT PK_PHANCONG PRIMARY KEY (MAGV, MALOP, MAMH, MAHK, MANAM),
    CONSTRAINT FK_PC_GV FOREIGN KEY (MAGV) REFERENCES GIAOVIEN(MAGV),
    CONSTRAINT FK_PC_LOP FOREIGN KEY (MALOP) REFERENCES LOP(MALOP),
    CONSTRAINT FK_PC_MH FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH),
    CONSTRAINT FK_PC_HK FOREIGN KEY (MAHK) REFERENCES HOCKY(MAHK),
    CONSTRAINT FK_PC_NAM FOREIGN KEY (MANAM) REFERENCES NAMHOC(MANAM)
) ON G_GV
GO

-- 15. THOIKHOABIEU
CREATE TABLE THOIKHOABIEU (
    MALOP CHAR(5) NOT NULL,
    MAMH CHAR(6) NOT NULL,
    MAGV CHAR(5) NOT NULL,
    MANAM CHAR(9) NOT NULL,
    MAHK CHAR(3) NOT NULL,
    THU INT CHECK (THU BETWEEN 2 AND 7),
    TIET INT CHECK (TIET BETWEEN 1 AND 10),
    MAPHONG CHAR(5),
    CONSTRAINT PK_TKB PRIMARY KEY (MALOP, MAMH, MAGV, MANAM, MAHK, THU, TIET),
    CONSTRAINT FK_TKB_LOP FOREIGN KEY (MALOP) REFERENCES LOP(MALOP),
    CONSTRAINT FK_TKB_MH FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH),
    CONSTRAINT FK_TKB_GV FOREIGN KEY (MAGV) REFERENCES GIAOVIEN(MAGV),
    CONSTRAINT FK_TKB_NAM FOREIGN KEY (MANAM) REFERENCES NAMHOC(MANAM),
    CONSTRAINT FK_TKB_HK FOREIGN KEY (MAHK) REFERENCES HOCKY(MAHK),
    CONSTRAINT FK_TKB_PH FOREIGN KEY (MAPHONG) REFERENCES PHONGHOC(MAPHONG),
    CONSTRAINT UQ_TKB_GV UNIQUE (MAGV, THU, TIET, MAHK, MANAM),
    CONSTRAINT UQ_TKB_PH UNIQUE (MAPHONG, THU, TIET, MAHK, MANAM),
    CONSTRAINT UQ_TKB_LOP UNIQUE (MALOP, THU, TIET, MAHK, MANAM)
) ON G_GV
GO

-- 16. TAIKHOAN
CREATE TABLE TAIKHOAN (
    USERNAME VARCHAR(20) NOT NULL,
    PASSWORD VARCHAR(255) NOT NULL,
    LOAI NVARCHAR(10) CHECK (LOAI IN (N'Admin',N'GV',N'HS')),
    MAGV CHAR(5) NULL,
    MAHS CHAR(6) NULL,
    TINHTRANG NVARCHAR(20) DEFAULT N'Hoạt động' CHECK (TINHTRANG IN (N'Hoạt động',N'Khóa',N'Tạm khóa')),
    NGAYTAO DATE DEFAULT GETDATE(),
    LANDANGNHAPCUOI DATETIME,
    CONSTRAINT PK_TK PRIMARY KEY (USERNAME),
    CONSTRAINT FK_TK_GV FOREIGN KEY (MAGV) REFERENCES GIAOVIEN(MAGV),
    CONSTRAINT FK_TK_HS FOREIGN KEY (MAHS) REFERENCES HOCSINH(MAHS)
) ON G_SYS
GO

-- ==================================================================================================================================================
-- PHẦN 3: CÁC CHỨC NĂNG PHÂN CÔNG CHO THÀNH VIÊN NHÓM
-- ==================================================================================================================================================

--=======================================================================================================--
--                                                                                                       --
--                                            CHƯƠNG 2                                                   --
--                                                                                                       --
--=======================================================================================================--

--==============================================================================--
-----------------------------1. Nguyễn Tấn Phát-----------------------------------
--==============================================================================--
-- 1. TRIGGER: Kiểm tra điểm hợp lệ
CREATE TRIGGER trg_KiemTraDiem
ON DIEM
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM inserted WHERE DIEM < 0 OR DIEM > 10)
    BEGIN
        RAISERROR (N'Điểm phải nằm trong khoảng từ 0 đến 10', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
    
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM HOCSINH_NAMHOC HSN
            WHERE HSN.MAHS = i.MAHS AND HSN.MANAM = i.MANAM
        )
    )
    BEGIN
        RAISERROR (N'Học sinh không thuộc lớp nào trong năm học này', 16, 1)
        ROLLBACK TRANSACTION
        RETURN
    END
END
GO

-- 2. PROCEDURE: Nhập điểm
CREATE PROC sp_NhapDiem
    @MAHS CHAR(6),
    @MAMH CHAR(6),
    @MAHK CHAR(3),
    @MANAM CHAR(9),
    @MALOAIDIEM CHAR(3),
    @DIEM DECIMAL(4,2),
    @GHICHU NVARCHAR(200) = NULL,
    @Result INT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION
    
    BEGIN TRY
        IF @DIEM < 0 OR @DIEM > 10
        BEGIN
            SET @Result = 0
            SET @Message = N'Điểm phải từ 0 đến 10'
            ROLLBACK TRANSACTION
            RETURN
        END
        
        IF EXISTS (
            SELECT 1 FROM DIEM 
            WHERE MAHS = @MAHS AND MAMH = @MAMH AND MAHK = @MAHK 
                AND MANAM = @MANAM AND MALOAIDIEM = @MALOAIDIEM
        )
        BEGIN
            UPDATE DIEM
            SET DIEM = @DIEM, NGAYNHAP = GETDATE(), GHICHU = @GHICHU
            WHERE MAHS = @MAHS AND MAMH = @MAMH AND MAHK = @MAHK 
                AND MANAM = @MANAM AND MALOAIDIEM = @MALOAIDIEM
            
            SET @Result = 1
            SET @Message = N'Cập nhật điểm thành công'
        END
        ELSE
        BEGIN
            INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM, NGAYNHAP, GHICHU)
            VALUES (@MAHS, @MAMH, @MAHK, @MANAM, @MALOAIDIEM, @DIEM, GETDATE(), @GHICHU)
            
            SET @Result = 1
            SET @Message = N'Thêm điểm thành công'
        END
        
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @Result = 0
        SET @Message = ERROR_MESSAGE()
    END CATCH
END
GO

-- 3. FUNCTION: Tính điểm trung bình môn học
CREATE OR ALTER FUNCTION fn_TinhDiemTBMon
(
    @MAHS CHAR(6),
    @MAMH CHAR(6),
    @MAHK CHAR(3),
    @MANAM CHAR(9)
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    -- 1. Kiểm tra xem có Điểm Thi chưa? (Bắt buộc phải có mới tính TB)
    IF NOT EXISTS (
        SELECT 1 FROM DIEM D 
        JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
        WHERE D.MAHS = @MAHS AND D.MAMH = @MAMH 
          AND D.MAHK = @MAHK AND D.MANAM = @MANAM 
          AND LD.TENLOAIDIEM = N'Điểm thi'
    )
        RETURN NULL; -- Chưa thi -> Chưa có điểm tổng kết môn

    -- 2. Kiểm tra xem có ít nhất 1 bài 1 tiết chưa?
    IF NOT EXISTS (
        SELECT 1 FROM DIEM D 
        JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
        WHERE D.MAHS = @MAHS AND D.MAMH = @MAMH 
          AND D.MAHK = @MAHK AND D.MANAM = @MANAM 
          AND LD.TENLOAIDIEM = N'Điểm 1 tiết'
    )
        RETURN NULL; -- Chưa có bài 1 tiết nào -> Chưa đủ cơ sở tính

    -- 3. Nếu đủ điều kiện, tính trung bình cộng theo hệ số
    DECLARE @DiemTB DECIMAL(10,2) = 0
    DECLARE @TongHeSo INT = 0
    
    SELECT 
        @DiemTB = @DiemTB + (D.DIEM * LD.HESODIEM),
        @TongHeSo = @TongHeSo + LD.HESODIEM
    FROM DIEM D
    INNER JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
    WHERE D.MAHS = @MAHS 
        AND D.MAMH = @MAMH 
        AND D.MAHK = @MAHK 
        AND D.MANAM = @MANAM
    
    IF @TongHeSo > 0
        RETURN ROUND(@DiemTB / @TongHeSo, 1)
    
    RETURN NULL
END
GO

-- 4.FUNCTION: Tính điểm trung bình học kỳ
CREATE OR ALTER FUNCTION fn_TinhDiemTBHocKy
(
    @MAHS CHAR(6),
    @MAHK CHAR(3),
    @MANAM CHAR(9)
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @MALOP CHAR(5)
    
    -- Lấy lớp của học sinh
    SELECT @MALOP = MALOP FROM HOCSINH_NAMHOC 
    WHERE MAHS = @MAHS AND MANAM = @MANAM

    IF @MALOP IS NULL RETURN NULL;

    -- 1. Đếm tổng số môn học lớp này PHẢI HỌC (được phân công)
    DECLARE @TongSoMonPhaiHoc INT
    SELECT @TongSoMonPhaiHoc = COUNT(DISTINCT MAMH) 
    FROM PHANCONG 
    WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK

    IF @TongSoMonPhaiHoc = 0 RETURN NULL;

    -- 2. Đếm số môn học ĐÃ CÓ ĐIỂM TB (Khác NULL)
    DECLARE @SoMonDaCoDiem INT
    SELECT @SoMonDaCoDiem = COUNT(DISTINCT PC.MAMH)
    FROM PHANCONG PC
    WHERE PC.MALOP = @MALOP AND PC.MANAM = @MANAM AND PC.MAHK = @MAHK
      AND dbo.fn_TinhDiemTBMon(@MAHS, PC.MAMH, @MAHK, @MANAM) IS NOT NULL

    -- 3. Nếu số môn có điểm < Tổng môn phải học -> Chưa tổng kết được
    IF @SoMonDaCoDiem < @TongSoMonPhaiHoc
        RETURN NULL;

    -- 4. Tính trung bình học kỳ
    DECLARE @DiemTB DECIMAL(10,2) = 0
    DECLARE @TongHeSo INT = 0
    
    SELECT 
        @DiemTB = @DiemTB + (dbo.fn_TinhDiemTBMon(@MAHS, MH.MAMH, @MAHK, @MANAM) * MH.HESO),
        @TongHeSo = @TongHeSo + MH.HESO
    FROM MONHOC MH
    WHERE MH.MAMH IN (
        SELECT DISTINCT MAMH FROM PHANCONG 
        WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK
    )
    
    IF @TongHeSo > 0
        RETURN ROUND(@DiemTB / @TongHeSo, 1)
    
    RETURN NULL
END
GO

-- 5.FUNCTION: Tính điểm trung bình cả năm
CREATE FUNCTION fn_TinhDiemTBNamHoc
(
    @MAHS CHAR(6),
    @MANAM CHAR(9)
)
RETURNS DECIMAL(4,2)
AS
BEGIN
    DECLARE @DiemHK1 DECIMAL(4,2)
    DECLARE @DiemHK2 DECIMAL(4,2)
    
    -- Lấy điểm TB từng học kỳ
    SELECT @DiemHK1 = dbo.fn_TinhDiemTBHocKy(@MAHS, 'HK1', @MANAM)
    SELECT @DiemHK2 = dbo.fn_TinhDiemTBHocKy(@MAHS, 'HK2', @MANAM)
    
    -- CHỈ TÍNH KHI CÓ ĐỦ ĐIỂM CẢ 2 HỌC KỲ
    IF @DiemHK1 IS NOT NULL AND @DiemHK2 IS NOT NULL
        RETURN ROUND((@DiemHK1 + @DiemHK2 * 2) / 3, 2)
    
    -- Nếu thiếu 1 trong 2 hoặc cả 2, trả về NULL (không hiển thị)
    RETURN NULL
END
GO
select * from hocsinh
declare @diemnam decimal(10,2)
set @diemnam = dbo.fn_TinhDiemTBNamHoc ('HS0001', '2024-2025')
print @diemnam

-- 6.FUNCTION: Xếp loại học lực
CREATE FUNCTION fn_XepLoaiHocLuc
(
    @DiemTB DECIMAL(4,2)
)
RETURNS NVARCHAR(20)
AS
BEGIN
    IF @DiemTB IS NULL
        RETURN N'Chưa có điểm'
    
    IF @DiemTB >= 9.0
        RETURN N'Xuất sắc'
    
    IF @DiemTB >= 8.0
        RETURN N'Giỏi'
    
    IF @DiemTB >= 6.5
        RETURN N'Khá'
    
    IF @DiemTB >= 5.0
        RETURN N'Trung bình'
    
    IF @DiemTB >= 3.5
        RETURN N'Yếu'
    
    RETURN N'Kém'
END
GO

-- 7. PROCEDURE: Lấy danh sách học sinh và điểm
CREATE OR ALTER PROC sp_GetDanhSachHocSinhVaDiem
    @MALOP CHAR(5),
    @MAMH CHAR(6),
    @MANAM CHAR(9),
    @MAHK CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        HS.MAHS,
        HS.HO + ' ' + HS.TEN AS HOTEN,
        HS.NGAYSINH,
        HS.GIOITINH,
        (SELECT TOP 1 D.DIEM FROM DIEM D 
         INNER JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
         WHERE D.MAHS = HS.MAHS AND D.MAMH = @MAMH AND D.MAHK = @MAHK 
           AND D.MANAM = @MANAM AND LD.TENLOAIDIEM = N'Điểm miệng'
         ORDER BY D.NGAYNHAP DESC) AS DIEMMIENG,
        
        (SELECT TOP 1 D.DIEM FROM DIEM D 
         INNER JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
         WHERE D.MAHS = HS.MAHS AND D.MAMH = @MAMH AND D.MAHK = @MAHK 
           AND D.MANAM = @MANAM AND LD.TENLOAIDIEM = N'Điểm 15 phút'
         ORDER BY D.NGAYNHAP DESC) AS DIEM15PHUT,
        
        (SELECT TOP 1 D.DIEM FROM DIEM D 
         INNER JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
         WHERE D.MAHS = HS.MAHS AND D.MAMH = @MAMH AND D.MAHK = @MAHK 
           AND D.MANAM = @MANAM AND LD.TENLOAIDIEM = N'Điểm 1 tiết'
         ORDER BY D.NGAYNHAP DESC) AS DIEM1TIET,
        
        (SELECT TOP 1 D.DIEM FROM DIEM D 
         INNER JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
         WHERE D.MAHS = HS.MAHS AND D.MAMH = @MAMH AND D.MAHK = @MAHK 
           AND D.MANAM = @MANAM AND LD.TENLOAIDIEM = N'Điểm thi'
         ORDER BY D.NGAYNHAP DESC) AS DIEMTHI,
        
        dbo.fn_TinhDiemTBMon(HS.MAHS, @MAMH, @MAHK, @MANAM) AS DIEMTBMON
        
    FROM HOCSINH HS
    INNER JOIN HOCSINH_NAMHOC HSN ON HS.MAHS = HSN.MAHS
    WHERE HSN.MALOP = @MALOP AND HSN.MANAM = @MANAM
        AND HS.TRANGTHAI = N'Đang học'
    ORDER BY HS.HO, HS.TEN
END
GO

-- 8.PROCEDURE: Lấy bảng điểm tổng hợp
CREATE PROC sp_GetBangDiemTongHop
    @MAHS CHAR(6),
    @MANAM CHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        HS.MAHS,
        HS.HO + ' ' + HS.TEN AS HOTEN,
        L.TENLOP,
        NH.TENNAM,
        dbo.fn_TinhDiemTBHocKy(@MAHS, 'HK1', @MANAM) AS DIEMTB_HK1,
        dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBHocKy(@MAHS, 'HK1', @MANAM)) AS XEPLOAI_HK1,
        dbo.fn_TinhDiemTBHocKy(@MAHS, 'HK2', @MANAM) AS DIEMTB_HK2,
        dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBHocKy(@MAHS, 'HK2', @MANAM)) AS XEPLOAI_HK2,
        dbo.fn_TinhDiemTBNamHoc(@MAHS, @MANAM) AS DIEMTB_CANAM,
        dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBNamHoc(@MAHS, @MANAM)) AS XEPLOAI_CANAM
        
    FROM HOCSINH HS
    INNER JOIN HOCSINH_NAMHOC HSN ON HS.MAHS = HSN.MAHS
    INNER JOIN LOP L ON HSN.MALOP = L.MALOP
    INNER JOIN NAMHOC NH ON HSN.MANAM = NH.MANAM
    WHERE HS.MAHS = @MAHS AND HSN.MANAM = @MANAM
END
GO
--==============================================================================--
-----------------------------2. Nguyễn Văn Anh Tuấn-------------------------------
--==============================================================================--

-- 1. Thêm constraint kiểm tra lý do vắng
ALTER TABLE DIEMDANH
ADD CONSTRAINT CHK_LyDoVang
    CHECK (
        (TRANGTHAI = N'Vắng có phép' AND LYDOVANG IS NOT NULL AND LYDOVANG <> '') OR
        (TRANGTHAI <> N'Vắng có phép')
    )
GO

-- 2. TRIGGER: TỰ ĐỘNG ĐIỂM DANH "CÓ MẶT" KHI THÊM HỌC SINH VÀO LỚP (TKB)
CREATE TRIGGER TRG_AutoDiemDanh_WhenTKB
ON THOIKHOABIEU
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy ngày hiện tại để tính thứ
    DECLARE @NgayHienTai DATE = CAST(GETDATE() AS DATE);
    DECLARE @ThuHienTai INT = DATEPART(WEEKDAY, GETDATE()); -- Mặc định: CN=1, T2=2, T3=3...

    -- Chỉ thực hiện nếu có tiết học trùng với ngày hôm nay
    -- Logic: JOIN bảng inserted với bảng HOCSINH_NAMHOC để lấy danh sách học sinh
    INSERT INTO DIEMDANH (MAHS, MAGV, MAMH, MANAM, MAHK, NGAYDIEMDANH, TIET, TRANGTHAI)
    SELECT 
        HSN.MAHS,
        i.MAGV,
        i.MAMH,
        i.MANAM,
        i.MAHK,
        @NgayHienTai,
        i.TIET,
        N'Có mặt' -- Mặc định là có mặt
    FROM inserted i
    INNER JOIN HOCSINH_NAMHOC HSN 
        ON i.MALOP = HSN.MALOP AND i.MANAM = HSN.MANAM
    WHERE i.THU = @ThuHienTai -- Chỉ tạo điểm danh nếu TKB vừa thêm đúng là thứ hôm nay
    AND NOT EXISTS (
        -- Kiểm tra để tránh trùng lặp nếu điểm danh đã tồn tại
        SELECT 1 FROM DIEMDANH DD
        WHERE DD.MAHS = HSN.MAHS 
          AND DD.NGAYDIEMDANH = @NgayHienTai
          AND DD.TIET = i.TIET
          AND DD.MANAM = i.MANAM
          AND DD.MAHK = i.MAHK
    );
END
GO

-- 3. PROCEDURE: ĐIỂM DANH HÀNG LOẠT (DÙNG CURSOR) - THEO LỚP + TIẾT + NGÀY
CREATE PROC SP_DiemDanh_HangLoat
    @MALOP CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @NGAY DATE,
    @TIET INT,
    @TRANGTHAI NVARCHAR(30),
    @LYDOVANG NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        -- Kiểm tra trạng thái hợp lệ
        IF @TRANGTHAI NOT IN (N'Có mặt', N'Vắng có phép', N'Vắng không phép', N'Đi muộn', N'Về sớm')
            THROW 50001, N'Trạng thái điểm danh không hợp lệ!', 1;

        -- Nếu vắng có phép → bắt buộc có lý do
        IF @TRANGTHAI = N'Vắng có phép' AND (@LYDOVANG IS NULL OR LTRIM(RTRIM(@LYDOVANG)) = '')
            THROW 50002, N'Phải nhập lý do khi vắng có phép!', 1;

        -- Cursor: duyệt từng học sinh trong lớp
        DECLARE @MAHS CHAR(6), @MAGV CHAR(5), @MAMH CHAR(6);

        DECLARE cur_DD CURSOR FOR
        SELECT HSN.MAHS, TKB.MAGV, TKB.MAMH
        FROM HOCSINH_NAMHOC HSN
        JOIN THOIKHOABIEU TKB ON HSN.MALOP = TKB.MALOP
        WHERE HSN.MALOP = @MALOP 
          AND HSN.MANAM = @MANAM
          AND TKB.MANAM = @MANAM
          AND TKB.MAHK = @MAHK
          AND TKB.TIET = @TIET
          AND TKB.THU = DATEPART(WEEKDAY, @NGAY) - 1; -- Chuyển về TKB (2=Thứ 2)

        OPEN cur_DD;
        FETCH NEXT FROM cur_DD INTO @MAHS, @MAGV, @MAMH;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Cập nhật hoặc thêm mới
            IF EXISTS (SELECT 1 FROM DIEMDANH WHERE MAHS = @MAHS AND NGAYDIEMDANH = @NGAY AND TIET = @TIET AND MANAM = @MANAM AND MAHK = @MAHK)
            BEGIN
                UPDATE DIEMDANH
                SET TRANGTHAI = @TRANGTHAI,
                    LYDOVANG = CASE WHEN @TRANGTHAI = N'Vắng có phép' THEN @LYDOVANG ELSE LYDOVANG END
                WHERE MAHS = @MAHS AND NGAYDIEMDANH = @NGAY AND TIET = @TIET AND MANAM = @MANAM AND MAHK = @MAHK;
            END
            ELSE
            BEGIN
                INSERT INTO DIEMDANH (MAHS, MAGV, MAMH, MANAM, MAHK, NGAYDIEMDANH, TIET, TRANGTHAI, LYDOVANG)
                VALUES (@MAHS, @MAGV, @MAMH, @MANAM, @MAHK, @NGAY, @TIET, @TRANGTHAI, 
                        CASE WHEN @TRANGTHAI = N'Vắng có phép' THEN @LYDOVANG ELSE NULL END);
            END

            FETCH NEXT FROM cur_DD INTO @MAHS, @MAGV, @MAMH;
        END

        CLOSE cur_DD;
        DEALLOCATE cur_DD;

        COMMIT;
        PRINT N'Điểm danh hàng loạt thành công!';
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur_DD') >= -1
        BEGIN
            CLOSE cur_DD; DEALLOCATE cur_DD;
        END
        ROLLBACK;
        DECLARE @ErrMsg NVARCHAR(400) = ERROR_MESSAGE();
        THROW 50000, @ErrMsg, 1;
    END CATCH
END
GO

-- 4. PROCEDURE: ĐIỂM DANH CÁ NHÂN (1 HỌC SINH)
CREATE PROC SP_DiemDanh_CaNhan
    @MAHS CHAR(6),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @NGAY DATE,
    @TIET INT,
    @TRANGTHAI NVARCHAR(30),
    @LYDOVANG NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        IF @TRANGTHAI NOT IN (N'Có mặt', N'Vắng có phép', N'Vắng không phép', N'Đi muộn', N'Về sớm')
            THROW 50001, N'Trạng thái không hợp lệ!', 1;

        IF @TRANGTHAI = N'Vắng có phép' AND (@LYDOVANG IS NULL OR LTRIM(RTRIM(@LYDOVANG)) = '')
            THROW 50002, N'Phải nhập lý do!', 1;

        -- Lấy thông tin GV, Môn từ TKB
        DECLARE @MAGV CHAR(5), @MAMH CHAR(6), @MALOP CHAR(5);

        SELECT @MALOP = HSN.MALOP
        FROM HOCSINH_NAMHOC HSN
        WHERE HSN.MAHS = @MAHS AND HSN.MANAM = @MANAM;

        SELECT TOP 1 @MAGV = MAGV, @MAMH = MAMH
        FROM THOIKHOABIEU
        WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND TIET = @TIET AND THU = DATEPART(WEEKDAY, @NGAY) - 1;

        IF @MAGV IS NULL
            THROW 50003, N'Không tìm thấy tiết học trong TKB!', 1;

        -- Cập nhật hoặc thêm
        IF EXISTS (SELECT 1 FROM DIEMDANH WHERE MAHS = @MAHS AND NGAYDIEMDANH = @NGAY AND TIET = @TIET AND MANAM = @MANAM AND MAHK = @MAHK)
        BEGIN
            UPDATE DIEMDANH
            SET TRANGTHAI = @TRANGTHAI,
                LYDOVANG = CASE WHEN @TRANGTHAI = N'Vắng có phép' THEN @LYDOVANG ELSE LYDOVANG END
            WHERE MAHS = @MAHS AND NGAYDIEMDANH = @NGAY AND TIET = @TIET AND MANAM = @MANAM AND MAHK = @MAHK;
        END
        ELSE
        BEGIN
            INSERT INTO DIEMDANH (MAHS, MAGV, MAMH, MANAM, MAHK, NGAYDIEMDANH, TIET, TRANGTHAI, LYDOVANG)
            VALUES (@MAHS, @MAGV, @MAMH, @MANAM, @MAHK, @NGAY, @TIET, @TRANGTHAI, 
                    CASE WHEN @TRANGTHAI = N'Vắng có phép' THEN @LYDOVANG ELSE NULL END);
        END

        COMMIT;
        PRINT N'Điểm danh cá nhân thành công!';
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO

-- 5. FUNCTION: THỐNG KÊ ĐIỂM DANH THEO HỌC SINH (TRONG HỌC KỲ)
CREATE FUNCTION FN_ThongKeDiemDanh_HS
(
    @MAHS CHAR(6),
    @MANAM CHAR(9),
    @MAHK CHAR(3)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        TRANGTHAI,
        COUNT(*) AS SoTiet,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM DIEMDANH WHERE MAHS = @MAHS AND MANAM = @MANAM AND MAHK = @MAHK), 2) AS TyLe
    FROM DIEMDANH
    WHERE MAHS = @MAHS AND MANAM = @MANAM AND MAHK = @MAHK
    GROUP BY TRANGTHAI
)
GO



--==============================================================================--
-----------------------------3. Nguyễn Long Vỹ------------------------------------
--==============================================================================--

-- 1. TRIGGER: Tự động tạo tài khoản khi thêm học sinh mới
CREATE TRIGGER TRG_AutoCreateAccount_HocSinh
ON HOCSINH
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO TAIKHOAN (USERNAME, PASSWORD, LOAI, MAHS, TINHTRANG, NGAYTAO)
    SELECT 
        i.MAHS,
        FORMAT(i.NGAYSINH, 'ddMMyyyy'), -- Mật khẩu = ngày sinh (ddMMyyyy)
        N'HS',
        i.MAHS,
        N'Hoạt động',
        GETDATE()
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MAHS = i.MAHS)
END
GO

-- 2. TRIGGER: Tự động tạo tài khoản khi thêm giáo viên mới
CREATE TRIGGER TRG_AutoCreateAccount_GiaoVien
ON GIAOVIEN
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO TAIKHOAN (USERNAME, PASSWORD, LOAI, MAGV, TINHTRANG, NGAYTAO)
    SELECT 
        i.MAGV,
        FORMAT(i.NGAYSINH, 'ddMMyyyy'), -- Mật khẩu = ngày sinh (ddMMyyyy)
        N'GV',
        i.MAGV,
        N'Hoạt động',
        GETDATE()
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE MAGV = i.MAGV)
END
GO

-- 3. PROCEDURE: DANH SÁCH TÀI KHOẢN
CREATE PROC SP_TaiKhoan_DanhSach
AS
BEGIN
    SELECT 
        USERNAME,
        LOAI,
        MAGV,
        MAHS,
        TINHTRANG,
        NGAYTAO,
        LANDANGNHAPCUOI
    FROM TAIKHOAN;
END
GO

-- 4. PROCEDURE: Reset mật khẩu
CREATE PROC SP_TaiKhoan_ResetMatKhau
    @USERNAME VARCHAR(20)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE USERNAME = @USERNAME)
    BEGIN
        PRINT N'Tài khoản không tồn tại!';
        RETURN;
    END

    -- Reset về mật khẩu mặc định (ngày sinh)
    DECLARE @NGAYSINH DATE;
    
    IF EXISTS (SELECT 1 FROM TAIKHOAN WHERE USERNAME = @USERNAME AND LOAI = N'HS')
    BEGIN
        SELECT @NGAYSINH = HS.NGAYSINH 
        FROM TAIKHOAN TK
        JOIN HOCSINH HS ON TK.MAHS = HS.MAHS
        WHERE TK.USERNAME = @USERNAME;
    END
    ELSE IF EXISTS (SELECT 1 FROM TAIKHOAN WHERE USERNAME = @USERNAME AND LOAI = N'GV')
    BEGIN
        SELECT @NGAYSINH = GV.NGAYSINH 
        FROM TAIKHOAN TK
        JOIN GIAOVIEN GV ON TK.MAGV = GV.MAGV
        WHERE TK.USERNAME = @USERNAME;
    END

    UPDATE TAIKHOAN
    SET PASSWORD = ISNULL(FORMAT(@NGAYSINH, 'ddMMyyyy'), '123456')
    WHERE USERNAME = @USERNAME;

    PRINT N'Đặt lại mật khẩu thành công!';
END
GO

-- 5 PROCEDURE. CẬP NHẬT TÌNH TRẠNG (KHÓA / MỞ)
CREATE PROC SP_TaiKhoan_CapNhatTinhTrang
    @USERNAME VARCHAR(20),
    @TINHTRANG NVARCHAR(20)
AS
BEGIN
    IF @TINHTRANG NOT IN (N'Hoạt động', N'Khóa', N'Tạm khóa')
    BEGIN
        PRINT N'Tình trạng không hợp lệ!';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM TAIKHOAN WHERE USERNAME = @USERNAME)
    BEGIN
        PRINT N'Tài khoản không tồn tại!';
        RETURN;
    END

    UPDATE TAIKHOAN
    SET TINHTRANG = @TINHTRANG
    WHERE USERNAME = @USERNAME;

    PRINT N'Cập nhật tình trạng thành công!';
END
GO
EXEC SP_TaiKhoan_CapNhatTinhTrang 'Admin','Hoạt động'
--==============================================================================--
-----------------------------4. Hồ Khắc Hòa---------------------------------------
--==============================================================================--

-- 1. FUNCTION: Kiểm tra trùng thời khóa biểu
CREATE FUNCTION FUNC_KIEMTRA_TKB
(
    @MALOP CHAR(5),
    @MAMH CHAR(6),
    @MAGV CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @THU INT,
    @TIET INT,
    @MAPHONG CHAR(5)
)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @TB NVARCHAR(200) = N'Hợp lệ';

    IF EXISTS (
        SELECT * FROM THOIKHOABIEU
        WHERE MALOP = @MALOP AND MANAM=@MANAM AND MAHK=@MAHK
        AND THU=@THU AND TIET=@TIET
    )
        SET @TB = N'Lỗi: Lớp đã có tiết này!';

    IF EXISTS (
        SELECT * FROM THOIKHOABIEU
        WHERE MAGV = @MAGV AND MANAM=@MANAM AND MAHK=@MAHK
        AND THU=@THU AND TIET=@TIET
    )
        SET @TB = N'Lỗi: Giáo viên đã có tiết dạy trùng!';

    IF EXISTS (
        SELECT * FROM THOIKHOABIEU
        WHERE MAPHONG = @MAPHONG AND MANAM=@MANAM AND MAHK=@MAHK
        AND THU=@THU AND TIET=@TIET
    )
        SET @TB = N'Lỗi: Phòng học đã có lớp khác!';

    RETURN @TB;
END
GO

-- 2. PROCEDURE: Thêm thời khóa biểu
CREATE PROC PROC_TKB_THEM
(
    @MALOP CHAR(5),
    @MAMH CHAR(6),
    @MAGV CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @THU INT,
    @TIET INT,
    @MAPHONG CHAR(5)
)
AS
BEGIN
    DECLARE @CHECK NVARCHAR(200);

    SET @CHECK = dbo.FUNC_KIEMTRA_TKB(@MALOP, @MAMH, @MAGV, @MANAM, @MAHK, @THU, @TIET, @MAPHONG);

    IF (@CHECK <> N'Hợp lệ')
    BEGIN
        RAISERROR(@CHECK, 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO THOIKHOABIEU(MALOP, MAMH, MAGV, MANAM, MAHK, THU, TIET, MAPHONG)
        VALUES (@MALOP, @MAMH, @MAGV, @MANAM, @MAHK, @THU, @TIET, @MAPHONG);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ERR NVARCHAR(4000) = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ERR,16,1);
    END CATCH
END
GO

exec PROC_TKB_THEM '10A2', 'MH004', 'GV001', '2024-2025', 'HK1', '5', '4', 'P102'
-- 3. THỦ TỤC XÓA SỬA KHÓA BIỂU
CREATE OR ALTER PROC PROC_TKB_SUA
(
    -- Khóa chính để xác định tiết học cần sửa
    @MALOP CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @THU INT,
    @TIET INT,
    -- Thông tin mới cần cập nhật
    @NEWMAMH CHAR(6),
    @NEWMAGV CHAR(5),
    @NEWMAPHONG CHAR(5)
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Kiểm tra tồn tại
        IF NOT EXISTS (SELECT 1 FROM THOIKHOABIEU WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET)
        BEGIN
            RAISERROR(N'Không tìm thấy tiết học này để sửa!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Kiểm tra trùng GIÁO VIÊN 
        IF EXISTS (
            SELECT 1 FROM THOIKHOABIEU 
            WHERE MAGV = @NEWMAGV AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET
            AND MALOP <> @MALOP 
        )
        BEGIN
            RAISERROR(N'Giáo viên này đã có lịch dạy ở lớp khác vào tiết này!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Kiểm tra trùng PHÒNG HỌC 
        IF EXISTS (
            SELECT 1 FROM THOIKHOABIEU 
            WHERE MAPHONG = @NEWMAPHONG AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET
            AND MALOP <> @MALOP
        )
        BEGIN
            RAISERROR(N'Phòng học này đã có lớp khác học vào tiết này!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        DELETE FROM THOIKHOABIEU 
        WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET;

        INSERT INTO THOIKHOABIEU(MALOP, MAMH, MAGV, MANAM, MAHK, THU, TIET, MAPHONG)
        VALUES (@MALOP, @NEWMAMH, @NEWMAGV, @MANAM, @MAHK, @THU, @TIET, @NEWMAPHONG);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ERR NVARCHAR(4000) = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ERR, 16, 1);
    END CATCH
END
GO

-- 4. THỦ TỤC XÓA THỜI KHÓA BIỂU
CREATE OR ALTER PROC PROC_TKB_XOA
(
    @MALOP CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @THU INT,
    @TIET INT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Kiểm tra tồn tại
        IF NOT EXISTS (SELECT 1 FROM THOIKHOABIEU WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET)
        BEGIN
            RAISERROR(N'Tiết học không tồn tại!', 16, 1);
            RETURN;
        END

        DELETE FROM THOIKHOABIEU 
        WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET;
    END TRY
    BEGIN CATCH
        DECLARE @ERR NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ERR, 16, 1);
    END CATCH
END
GO

-- 5. PROCEDURE - CHức năng tìm thời khóa biểu theo mã giáo viên, mã lớp, thứ, tiết
CREATE PROCEDURE PROC_TKB_TIMKIEM
(
    @MAGV CHAR(5) = NULL,
    @MALOP CHAR(5) = NULL,
    @THU INT = NULL,
    @TIET INT = NULL
)
AS
BEGIN
    SELECT *
    FROM THOIKHOABIEU
    WHERE (@MAGV IS NULL OR MAGV = @MAGV)
      AND (@MALOP IS NULL OR MALOP = @MALOP)
      AND (@THU IS NULL OR THU = @THU)
      AND (@TIET IS NULL OR TIET = @TIET)
    ORDER BY THU, TIET;
END
GO
--==============================================================================--
-----------------------------5. Trần Tuấn Khoa------------------------------------
--==============================================================================--

-- 1. PROCEDURE: Thống kê trang chủ
CREATE PROC SP_ThongKe_TrangChu
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        N'Tổng số học sinh' AS ChiTieu, 
        COUNT(MAHS) AS SoLuong 
    FROM HOCSINH WHERE TRANGTHAI = N'Đang học'
    
    UNION ALL
    
    SELECT 
        N'Tổng số giáo viên', 
        COUNT(MAGV) 
    FROM GIAOVIEN WHERE TRANGTHAI = N'Đang làm'
    
    UNION ALL
    
    SELECT 
        N'Tổng số lớp', 
        COUNT(MALOP) 
    FROM LOP
END
GO

-- 2. FUNCTION: Thống kê sĩ số theo khối
CREATE OR ALTER FUNCTION FN_ThongKe_SiSoTheoKhoi()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        K.TENKHOI,
        ISNULL(SUM(L.SISO), 0) AS TongSiSo
    FROM KHOI K
    LEFT JOIN LOP L ON K.MAKHOI = L.MAKHOI
    GROUP BY K.TENKHOI
)
GO

-- 3. PROCEDURE: Thống kê xếp loại học lực theo khối (cho biểu đồ)
CREATE OR ALTER PROC SP_ThongKe_XepLoaiTheoKhoi
    @MANAM CHAR(9),
    @MAHK CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Sử dụng bảng tạm để tính toán trước
    SELECT 
        HS.MAHS,
        L.MAKHOI,
        K.TENKHOI,
        -- Gọi hàm tính điểm trung bình học kỳ từ file SQL gốc của bạn
        dbo.fn_TinhDiemTBHocKy(HS.MAHS, @MAHK, @MANAM) AS DiemTB
    INTO #TempDiem
    FROM HOCSINH HS
    INNER JOIN HOCSINH_NAMHOC HSN ON HS.MAHS = HSN.MAHS
    INNER JOIN LOP L ON HSN.MALOP = L.MALOP
    INNER JOIN KHOI K ON L.MAKHOI = K.MAKHOI
    WHERE HSN.MANAM = @MANAM
        AND HS.TRANGTHAI = N'Đang học'

    -- Xếp loại và thống kê
    SELECT 
        T.TENKHOI,
        CASE 
            WHEN T.DiemTB IS NULL THEN N'Chưa có điểm'
            WHEN T.DiemTB >= 8.0 THEN N'Giỏi' -- Gộp Xuất sắc vào Giỏi cho gọn biểu đồ
            WHEN T.DiemTB >= 6.5 THEN N'Khá'
            WHEN T.DiemTB >= 5.0 THEN N'Trung bình'
            ELSE N'Yếu/Kém'
        END AS XepLoai,
        COUNT(*) AS SoLuong
    FROM #TempDiem T
    GROUP BY T.TENKHOI, 
        CASE 
            WHEN T.DiemTB IS NULL THEN N'Chưa có điểm'
            WHEN T.DiemTB >= 8.0 THEN N'Giỏi'
            WHEN T.DiemTB >= 6.5 THEN N'Khá'
            WHEN T.DiemTB >= 5.0 THEN N'Trung bình'
            ELSE N'Yếu/Kém'
        END
    ORDER BY T.TENKHOI
    
    DROP TABLE #TempDiem
END
GO

-- 4. PROCEDURE: Thống kê xếp loại tổng hợp toàn trường (cho biểu đồ tròn)
CREATE PROC SP_ThongKe_XepLoaiToanTruong
    @MANAM CHAR(9),
    @MAHK CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBHocKy(HS.MAHS, @MAHK, @MANAM)) AS XepLoai,
        COUNT(*) AS SoLuong,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS TyLe
    FROM HOCSINH HS
    INNER JOIN HOCSINH_NAMHOC HSN ON HS.MAHS = HSN.MAHS
    WHERE HSN.MANAM = @MANAM
        AND HS.TRANGTHAI = N'Đang học'
        AND dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBHocKy(HS.MAHS, @MAHK, @MANAM)) <> N'Chưa có điểm'
    GROUP BY dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBHocKy(HS.MAHS, @MAHK, @MANAM))
    ORDER BY 
        CASE dbo.fn_XepLoaiHocLuc(dbo.fn_TinhDiemTBHocKy(HS.MAHS, @MAHK, @MANAM))
            WHEN N'Xuất sắc' THEN 1
            WHEN N'Giỏi' THEN 2
            WHEN N'Khá' THEN 3
            WHEN N'Trung bình' THEN 4
            WHEN N'Yếu' THEN 5
            WHEN N'Kém' THEN 6
            ELSE 7
        END
END
GO
-----------------------------------------------------------------------------------------
--                                                                                     --
--                                  CHỨC NĂNG CHUNG                                    --
--                                                                                     --
-----------------------------------------------------------------------------------------

-- =============================================
-- PHẦN 4: TẠO TRIGGERS
-- =============================================

-- 1. TRIGGER: Cập nhật sĩ số lớp
CREATE TRIGGER TRG_UpdateSiSo
ON HOCSINH_NAMHOC
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cập nhật khi thêm học sinh
    UPDATE LOP
    SET SISO = (
        SELECT COUNT(*) 
        FROM HOCSINH_NAMHOC HSN 
        WHERE HSN.MALOP = LOP.MALOP
    )
    WHERE MALOP IN (SELECT MALOP FROM inserted)
    
    -- Cập nhật khi xóa học sinh
    UPDATE LOP
    SET SISO = (
        SELECT COUNT(*) 
        FROM HOCSINH_NAMHOC HSN 
        WHERE HSN.MALOP = LOP.MALOP
    )
    WHERE MALOP IN (SELECT MALOP FROM deleted)
END
GO

-- =============================================
-- PHẦN 5: TẠO STORED PROCEDURES
-- =============================================
-- 1. PROCEDURE: Lấy danh sách lớp
CREATE PROC sp_GetDanhSachLop
    @MANAM CHAR(9),
    @MAHK CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT DISTINCT 
        L.MALOP,
        L.TENLOP,
        K.TENKHOI,
        L.SISO,
        GV.HOTEN AS GVCN
    FROM LOP L
    INNER JOIN KHOI K ON L.MAKHOI = K.MAKHOI
    LEFT JOIN GIAOVIEN GV ON L.MAGVCN = GV.MAGV
    WHERE EXISTS (
        SELECT 1 FROM HOCSINH_NAMHOC HSN 
        WHERE HSN.MALOP = L.MALOP AND HSN.MANAM = @MANAM
    )
    ORDER BY L.TENLOP
END
GO

-- 2. PROCEDURE: Tìm kiếm lớp (Theo Mã Lớp và Mã Khối)
CREATE OR ALTER PROC sp_TimKiemLop
    @MALOP NVARCHAR(50) = NULL,
    @MAKHOI CHAR(3) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        L.MALOP,
        L.TENLOP,
        L.MAKHOI,
        K.TENKHOI,
        L.SISO,
        L.MAGVCN,
        GV.HOTEN AS TENGVCN
    FROM LOP L
    INNER JOIN KHOI K ON L.MAKHOI = K.MAKHOI
    LEFT JOIN GIAOVIEN GV ON L.MAGVCN = GV.MAGV
    WHERE (@MALOP IS NULL OR L.MALOP LIKE '%' + @MALOP + '%')
      AND (@MAKHOI IS NULL OR L.MAKHOI = @MAKHOI)
    ORDER BY L.TENLOP
END
GO

-- 3. PROCEDURE: Thêm lớp mới
CREATE OR ALTER PROC sp_ThemLop
    @MALOP CHAR(5),
    @TENLOP NVARCHAR(30),
    @MAKHOI CHAR(3),
    @MAGVCN CHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra mã lớp đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Mã lớp đã tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra giáo viên chủ nhiệm (nếu có nhập)
    IF @MAGVCN IS NOT NULL AND NOT EXISTS (SELECT 1 FROM GIAOVIEN WHERE MAGV = @MAGVCN)
    BEGIN
        RAISERROR(N'Mã giáo viên không tồn tại!', 16, 1);
        RETURN;
    END

    -- Thêm lớp mới (Sỉ số mặc định là 0)
    INSERT INTO LOP (MALOP, TENLOP, MAKHOI, SISO, MAGVCN)
    VALUES (@MALOP, @TENLOP, @MAKHOI, 0, @MAGVCN)
END
GO

-- 4. PROCEDURE: Cập nhật thông tin lớp
CREATE OR ALTER PROC sp_SuaLop
    @MALOP CHAR(5),
    @TENLOP NVARCHAR(30),
    @MAKHOI CHAR(3),
    @MAGVCN CHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE LOP
    SET TENLOP = @TENLOP,
        MAKHOI = @MAKHOI,
        MAGVCN = @MAGVCN
    WHERE MALOP = @MALOP
END
GO
select * from hocsinh
-- 5. PROCEDURE: Xóa lớp học
CREATE OR ALTER PROC sp_XoaLop
    @MALOP CHAR(5)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra Học sinh
    IF EXISTS (SELECT 1 FROM HOCSINH_NAMHOC WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Không thể xóa lớp này vì đang có học sinh theo học!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra Thời khóa biểu
    IF EXISTS (SELECT 1 FROM THOIKHOABIEU WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Không thể xóa lớp này vì đã được xếp thời khóa biểu!', 16, 1);
        RETURN;
    END
    
    -- 3. MỚI: Kiểm tra Phân công
    IF EXISTS (SELECT 1 FROM PHANCONG WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Không thể xóa lớp này vì đang có phân công giảng dạy!', 16, 1);
        RETURN;
    END

    -- Nếu an toàn thì xóa
    DELETE FROM LOP WHERE MALOP = @MALOP
END
GO

-- 6. PROCEDURE: Phân lớp cho học sinh (Thêm mới hoặc Chuyển lớp)
CREATE OR ALTER PROC SP_PhanLopHocSinh
    @MAHS CHAR(6),
    @MALOP CHAR(5),
    @MANAM CHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra tồn tại
    IF NOT EXISTS (SELECT 1 FROM HOCSINH WHERE MAHS = @MAHS)
    BEGIN
        RAISERROR(N'Học sinh không tồn tại!', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP)
    BEGIN
        RAISERROR(N'Lớp không tồn tại!', 16, 1);
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM NAMHOC WHERE MANAM = @MANAM)
    BEGIN
        RAISERROR(N'Năm học không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra xem học sinh đã có lớp trong năm này chưa
    IF EXISTS (SELECT 1 FROM HOCSINH_NAMHOC WHERE MAHS = @MAHS AND MANAM = @MANAM)
    BEGIN
        -- Nếu đã có -> Cập nhật (Chuyển lớp)
        UPDATE HOCSINH_NAMHOC
        SET MALOP = @MALOP
        WHERE MAHS = @MAHS AND MANAM = @MANAM;
    END
    ELSE
    BEGIN
        -- Chưa có -> Thêm mới
        INSERT INTO HOCSINH_NAMHOC (MAHS, MANAM, MALOP)
        VALUES (@MAHS, @MANAM, @MALOP);
    END
END
GO

-- =============================================
-- PHẦN 6: TẠO STORED PROCEDURES
-- =============================================
--=======================================================================================================--
--                                                                                                       --
--                                            CHƯƠNG 3                                                   --
--                                                                                                       --
--=======================================================================================================--

-- ---------------------------------------------------------------------------------------
-- NV2. PHÂN QUYỀN GIÁO VIÊN (KHỚP GIAO DIỆN: TRANG CHỦ, NHẬP ĐIỂM, TKB, ĐIỂM DANH)
-- ---------------------------------------------------------------------------------------
-- 1. Tạo Role
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'GV_ROLE')
    CREATE ROLE GV_ROLE;
GO

-- 2. View 1: Trang chủ & Thông tin cá nhân
-- Xem thông tin bản thân và lớp mình chủ nhiệm (Home page)
CREATE OR ALTER VIEW VW_GV_ThongTinVaLopCN AS
SELECT GV.HOTEN, GV.MAGV, L.MALOP AS LOP_CHUNHIEM, L.TENLOP
FROM GIAOVIEN GV
LEFT JOIN LOP L ON GV.MAGV = L.MAGVCN
JOIN TAIKHOAN TK ON GV.MAGV = TK.MAGV
WHERE TK.USERNAME = CURRENT_USER;
GO

select * from TAIKHOAN

EXECUTE AS USER = 'GV001';
SELECT * FROM VW_GV_ThongTinVaLopCN;
SELECT * FROM VW_GV_TKB;
SELECT * FROM VW_GV_NhapDiem;
SELECT * FROM VW_GV_XemDiem;
REVERT; -- Quay lại quyền admin

-- 3. View 2: Thời khóa biểu
-- Xem TKB các lớp mình dạy (Menu: Thời khóa biểu)
CREATE OR ALTER VIEW VW_GV_TKB AS
SELECT TKB.*, MH.TENMH, L.TENLOP, PH.TENPHONG
FROM THOIKHOABIEU TKB
JOIN TAIKHOAN TK ON TKB.MAGV = TK.MAGV
JOIN MONHOC MH ON TKB.MAMH = MH.MAMH
JOIN LOP L ON TKB.MALOP = L.MALOP
LEFT JOIN PHONGHOC PH ON TKB.MAPHONG = PH.MAPHONG
WHERE TK.USERNAME = CURRENT_USER;
GO

-- 4. View 3: Quản lý điểm (Cần thiết cho chức năng Nhập điểm)
-- Giáo viên cần thấy danh sách HS ở các lớp mình ĐƯỢC PHÂN CÔNG DẠY
CREATE OR ALTER VIEW VW_GV_NhapDiem AS
SELECT 
    PC.MAGV, PC.MALOP, PC.MAMH, PC.MANAM, PC.MAHK,
    HS.MAHS, HS.HO, HS.TEN,
    MH.TENMH
FROM PHANCONG PC
JOIN HOCSINH_NAMHOC HSN ON PC.MALOP = HSN.MALOP AND PC.MANAM = HSN.MANAM
JOIN HOCSINH HS ON HSN.MAHS = HS.MAHS
JOIN MONHOC MH ON PC.MAMH = MH.MAMH
JOIN TAIKHOAN TK ON PC.MAGV = TK.MAGV
WHERE TK.USERNAME = CURRENT_USER;
GO

-- View xem điểm hiện có của HS trong các lớp mình dạy
CREATE OR ALTER VIEW VW_GV_XemDiem AS
SELECT D.* FROM DIEM D
JOIN PHANCONG PC ON D.MAMH = PC.MAMH AND D.MANAM = PC.MANAM 
                 AND D.MAHK = PC.MAHK AND D.MAHS IN (SELECT MAHS FROM HOCSINH_NAMHOC WHERE MALOP = PC.MALOP AND MANAM=PC.MANAM)
JOIN TAIKHOAN TK ON PC.MAGV = TK.MAGV
WHERE TK.USERNAME = CURRENT_USER;
GO

-- 5. View 4: Điểm danh (Chỉ dành cho GVCN theo mô tả giao diện)
-- Xem và quản lý điểm danh của lớp mình chủ nhiệm
CREATE OR ALTER VIEW VW_GV_DiemDanhChuNhiem AS
SELECT DD.*, HS.HO, HS.TEN
FROM DIEMDANH DD
JOIN HOCSINH HS ON DD.MAHS = HS.MAHS
JOIN HOCSINH_NAMHOC HSN ON HS.MAHS = HSN.MAHS
JOIN LOP L ON HSN.MALOP = L.MALOP -- Lớp của học sinh
JOIN TAIKHOAN TK ON L.MAGVCN = TK.MAGV -- Tài khoản là GVCN của lớp đó
WHERE TK.USERNAME = CURRENT_USER;
GO

-- 6. Cấp quyền cho GV_ROLE
GRANT SELECT ON VW_GV_ThongTinVaLopCN TO GV_ROLE;
GRANT SELECT ON VW_GV_TKB TO GV_ROLE;
GRANT SELECT ON VW_GV_NhapDiem TO GV_ROLE;
GRANT SELECT ON VW_GV_XemDiem TO GV_ROLE;
GRANT SELECT ON VW_GV_DiemDanhChuNhiem TO GV_ROLE;

-- Chức năng: Nhập/Lưu điểm (Mô tả giao diện mục II.2)
GRANT INSERT, UPDATE, SELECT ON DIEM TO GV_ROLE;

-- Chức năng: Điểm danh (Mô tả giao diện mục II.4 - Lưu thông tin điểm danh)
GRANT INSERT, UPDATE, SELECT ON DIEMDANH TO GV_ROLE;
GO

-- ---------------------------------------------------------------------------------------
-- NV3. PHÂN QUYỀN HỌC SINH (KHỚP GIAO DIỆN: TRANG CHỦ, ĐIỂM, TKB)
-- ---------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'HS_ROLE')
    CREATE ROLE HS_ROLE;
GO

-- 1. Trang chủ (Thông tin cá nhân & Lớp đang học)
CREATE OR ALTER VIEW VW_HS_TrangChu AS
SELECT HS.*, L.TENLOP, GV.HOTEN AS GVCN
FROM HOCSINH HS
JOIN HOCSINH_NAMHOC HSN ON HS.MAHS = HSN.MAHS
JOIN LOP L ON HSN.MALOP = L.MALOP
LEFT JOIN GIAOVIEN GV ON L.MAGVCN = GV.MAGV
JOIN TAIKHOAN TK ON HS.MAHS = TK.MAHS
WHERE TK.USERNAME = CURRENT_USER;
GO

-- 2. Xem điểm chi tiết của học sinh
CREATE OR ALTER PROC sp_HS_XemDiemChiTiet
    @MAHS CHAR(6),
    @MANAM CHAR(9),
    @MAHK CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MH.MAMH,
        MH.TENMH,
        
        -- Diem Mieng
        STUFF((
            SELECT ', ' + FORMAT(D.DIEM, 'N1')
            FROM DIEM D JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
            WHERE D.MAHS = @MAHS AND D.MAMH = MH.MAMH AND D.MANAM = @MANAM AND D.MAHK = @MAHK 
            AND LD.TENLOAIDIEM = N'Điểm miệng'
            ORDER BY D.NGAYNHAP FOR XML PATH('')
        ), 1, 2, '') AS DiemMieng,

        -- Diem 15p
        STUFF((
            SELECT ', ' + FORMAT(D.DIEM, 'N1')
            FROM DIEM D JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
            WHERE D.MAHS = @MAHS AND D.MAMH = MH.MAMH AND D.MANAM = @MANAM AND D.MAHK = @MAHK 
            AND LD.TENLOAIDIEM = N'Điểm 15 phút'
            ORDER BY D.NGAYNHAP FOR XML PATH('')
        ), 1, 2, '') AS Diem15Phut,

        -- Diem 1 Tiet
        STUFF((
            SELECT ', ' + FORMAT(D.DIEM, 'N1')
            FROM DIEM D JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
            WHERE D.MAHS = @MAHS AND D.MAMH = MH.MAMH AND D.MANAM = @MANAM AND D.MAHK = @MAHK 
            AND LD.TENLOAIDIEM = N'Điểm 1 tiết'
            ORDER BY D.NGAYNHAP FOR XML PATH('')
        ), 1, 2, '') AS Diem1Tiet,

        -- Diem Thi
        (
            SELECT TOP 1 FORMAT(D.DIEM, 'N1')
            FROM DIEM D JOIN LOAIDIEM LD ON D.MALOAIDIEM = LD.MALOAIDIEM
            WHERE D.MAHS = @MAHS AND D.MAMH = MH.MAMH AND D.MANAM = @MANAM AND D.MAHK = @MAHK 
            AND LD.TENLOAIDIEM = N'Điểm thi'
        ) AS DiemThi,

        -- TB MON: Sẽ là NULL nếu thiếu điểm (nhờ hàm fn_TinhDiemTBMon)
        CAST(dbo.fn_TinhDiemTBMon(@MAHS, MH.MAMH, @MAHK, @MANAM) AS DECIMAL(4,1)) AS DiemTBMon

    FROM MONHOC MH
    WHERE EXISTS (
        SELECT 1 FROM HOCSINH_NAMHOC HSN JOIN PHANCONG PC ON HSN.MALOP = PC.MALOP
        WHERE HSN.MAHS = @MAHS AND HSN.MANAM = @MANAM 
        AND PC.MAHK = @MAHK AND PC.MANAM = @MANAM AND PC.MAMH = MH.MAMH
    ) 
    ORDER BY MH.TENMH;
END
GO

-- 3. Xem thời khóa biểu
CREATE OR ALTER PROC sp_HS_XemThoiKhoaBieu
    @MAHS CHAR(6),
    @MANAM CHAR(9),
    @MAHK CHAR(3)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        TKB.THU,
        TKB.TIET,
        MH.TENMH,
        GV.HOTEN AS TENGV,
        ISNULL(PH.TENPHONG, N'Đang cập nhật') AS TENPHONG
    FROM THOIKHOABIEU TKB
    -- 1. Tìm lớp của học sinh trong năm học đó
    INNER JOIN HOCSINH_NAMHOC HSN 
        ON TKB.MALOP = HSN.MALOP AND TKB.MANAM = HSN.MANAM
    -- 2. Lấy tên môn học
    INNER JOIN MONHOC MH 
        ON TKB.MAMH = MH.MAMH
    -- 3. Lấy tên giáo viên
    INNER JOIN GIAOVIEN GV 
        ON TKB.MAGV = GV.MAGV
    -- 4. Lấy tên phòng học (Left Join vì có thể chưa xếp phòng)
    LEFT JOIN PHONGHOC PH 
        ON TKB.MAPHONG = PH.MAPHONG
    WHERE HSN.MAHS = @MAHS 
      AND TKB.MANAM = @MANAM 
      AND TKB.MAHK = @MAHK
    ORDER BY TKB.THU, TKB.TIET -- Sắp xếp để dễ hiển thị
END
GO

-- 4. Cấp quyền HS_ROLE (Chỉ xem)
----- Cấp quyền cho Học sinh chạy procedure này
GRANT EXECUTE ON sp_HS_XemThoiKhoaBieu TO HS_ROLE;
GO
---- Cấp quyền xem điểm cho học sinh
GRANT EXECUTE ON sp_HS_XemDiemChiTiet TO HS_ROLE;
GO

-- ---------------------------------------------------------------------------------------
-- NV4. PHÂN QUYỀN ADMIN (TOÀN QUYỀN)
-- ---------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ADMIN_ROLE')
    CREATE ROLE ADMIN_ROLE;
GO
EXEC sp_addrolemember 'db_owner', 'ADMIN_ROLE';
GO

-- ---------------------------------------------------------------------------------------
-- TỰ ĐỘNG TẠO USER & GÁN ROLE
-- ---------------------------------------------------------------------------------------
CREATE OR ALTER PROC SP_DongBoTaiKhoanSQL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Username VARCHAR(20), @Password VARCHAR(255), @Loai NVARCHAR(10), @SQL NVARCHAR(MAX)
    DECLARE @Count INT = 0

    DECLARE cur_Account CURSOR FOR 
    SELECT USERNAME, PASSWORD, LOAI FROM TAIKHOAN WHERE TINHTRANG = N'Hoạt động'

    OPEN cur_Account
    FETCH NEXT FROM cur_Account INTO @Username, @Password, @Loai

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 1. Tạo Login (Server Level)
        IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = @Username)
        BEGIN
            SET @SQL = 'CREATE LOGIN [' + @Username + '] WITH PASSWORD = ''' + @Password + ''', CHECK_POLICY = OFF'
            EXEC(@SQL)
        END

        -- 2. Tạo User (Database Level)
        IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = @Username)
        BEGIN
            SET @SQL = 'CREATE USER [' + @Username + '] FOR LOGIN [' + @Username + ']'
            EXEC(@SQL)
        END

        -- 3. Gán Role mặc định dựa trên loại TK
        -- Xóa role cũ trước để tránh lỗi duplicate
        EXEC sp_droprolemember 'GV_ROLE', @Username
        EXEC sp_droprolemember 'HS_ROLE', @Username
        EXEC sp_droprolemember 'ADMIN_ROLE', @Username

        IF @Loai = 'GV' EXEC sp_addrolemember 'GV_ROLE', @Username
        ELSE IF @Loai = 'HS' EXEC sp_addrolemember 'HS_ROLE', @Username
        ELSE IF @Loai = 'Admin' EXEC sp_addrolemember 'ADMIN_ROLE', @Username

        SET @Count = @Count + 1
        FETCH NEXT FROM cur_Account INTO @Username, @Password, @Loai
    END

    CLOSE cur_Account; 
    DEALLOCATE cur_Account;
    
    SELECT N'Đã đồng bộ thành công ' + CAST(@Count AS NVARCHAR(10)) + N' tài khoản xuống hệ thống bảo mật SQL.' AS Message
END
GO

-- ---------------------------------------------------------------------------------------
-- NV5: HỦY QUYỀN & BẢO TRÌ HỆ THỐNG (Hoàn thiện chi tiết)
-- ---------------------------------------------------------------------------------------
-- Hàm hỗ trợ kiểm tra Role của User (nếu SQL Server bản cũ không có IS_ROLEMEMBER cho user khác)
-- Tuy nhiên, cách đơn giản hơn là JOIN các bảng hệ thống
CREATE OR ALTER VIEW VW_UserRoles AS
SELECT 
    DP1.name AS Username, 
    DP2.name AS RoleName
FROM sys.database_role_members AS DRM
RIGHT JOIN sys.database_principals AS DP1 ON DRM.member_principal_id = DP1.principal_id
LEFT JOIN sys.database_principals AS DP2 ON DRM.role_principal_id = DP2.principal_id
WHERE DP1.type IN ('S', 'U')
GO

-- 1. THỦ TỤC CẤP/HỦY QUYỀN
CREATE OR ALTER PROC SP_CapNhatQuyenUser
    @Username VARCHAR(20),
    @RoleMoi NVARCHAR(50) -- 'ADMIN_ROLE', 'GV_ROLE', 'HS_ROLE', 'NONE'
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra User có tồn tại trong DB chưa
    IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = @Username)
    BEGIN
        RAISERROR(N'User chưa tồn tại trong SQL Security. Vui lòng chạy Đồng bộ hệ thống trước!', 16, 1);
        RETURN;
    END

    -- 1. Gỡ bỏ tất cả các Role cũ trong SQL Security
    BEGIN TRY EXEC sp_droprolemember 'ADMIN_ROLE', @Username END TRY BEGIN CATCH END CATCH
    BEGIN TRY EXEC sp_droprolemember 'GV_ROLE', @Username END TRY BEGIN CATCH END CATCH
    BEGIN TRY EXEC sp_droprolemember 'HS_ROLE', @Username END TRY BEGIN CATCH END CATCH

    -- 2. Cấp Role mới và Cập nhật bảng TAIKHOAN
    IF @RoleMoi <> 'NONE'
    BEGIN
        -- Cấp quyền SQL
        EXEC sp_addrolemember @RoleMoi, @Username;

        -- Cập nhật loại tài khoản trong bảng TAIKHOAN để hiển thị đúng trên Web
        DECLARE @LoaiApp NVARCHAR(10);
        IF @RoleMoi = 'ADMIN_ROLE' SET @LoaiApp = 'Admin';
        ELSE IF @RoleMoi = 'GV_ROLE' SET @LoaiApp = 'GV';
        ELSE IF @RoleMoi = 'HS_ROLE' SET @LoaiApp = 'HS';

        UPDATE TAIKHOAN 
        SET LOAI = @LoaiApp 
        WHERE USERNAME = @Username;
    END
    ELSE
    BEGIN
        -- Trường hợp hủy quyền (NONE) -> Có thể để trống hoặc set về mặc định tùy logic
        -- Ở đây giữ nguyên loại cũ hoặc set về null tùy bạn, nhưng thường thì hủy quyền SQL 
        -- đồng nghĩa user đó bị "treo", ta có thể không cần update bảng TAIKHOAN hoặc set TINHTRANG = 'Khóa'
        PRINT N'Đã hủy quyền SQL.';
    END
END
GO

select * from taikhoan

-- 2. SỬA LỖI SQL KHÔNG CHẠY (FIX ORPHAN USERS)
--    Tình huống: Khi Restore database sang máy khác, User trong DB bị mất liên kết với Login.
CREATE OR ALTER PROC SP_NV5_FixLoiDangNhap
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Username NVARCHAR(100)
    DECLARE @Count INT = 0
    DECLARE @ResultTable TABLE (Message NVARCHAR(500))

    -- Tìm các user bị lỗi (Có trong DB nhưng không khớp với Login Server)
    DECLARE cur_FixUser CURSOR FOR
    SELECT name 
    FROM sys.database_principals 
    WHERE type IN ('S', 'U') -- SQL User
      AND authentication_type <> 2 
      AND name NOT IN ('dbo', 'guest', 'sys', 'INFORMATION_SCHEMA')

    OPEN cur_FixUser
    FETCH NEXT FROM cur_FixUser INTO @Username

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Nếu tìm thấy Login trùng tên trên Server -> Tự động nối lại
        IF EXISTS (SELECT name FROM sys.server_principals WHERE name = @Username)
        BEGIN
            -- Lệnh này sẽ map lại User trong DB với Login trên Server
            EXEC sp_change_users_login 'Auto_Fix', @Username;
            INSERT INTO @ResultTable VALUES (N'-> Đã sửa lỗi đăng nhập cho: ' + @Username);
            SET @Count = @Count + 1;
        END
        
        FETCH NEXT FROM cur_FixUser INTO @Username
    END

    CLOSE cur_FixUser
    DEALLOCATE cur_FixUser

    IF @Count = 0 
        INSERT INTO @ResultTable VALUES (N'Hệ thống bình thường, không có user bị lỗi Orphan.');
        
    -- Trả về kết quả để hiển thị lên Web (nếu gọi từ Web)
    SELECT * FROM @ResultTable;
END
GO

--3. THỦ TỤC LẤY DANH SÁCH USER VÀ ROLE HIỆN TẠI
CREATE OR ALTER PROC SP_LayDanhSachPhanQuyen
AS
BEGIN
    SELECT 
        TK.USERNAME,
        TK.LOAI AS LoaiTaiKhoan,
        -- Kiểm tra User này đang thuộc Role nào trong SQL bằng cách JOIN bảng hệ thống
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_role_members rm
                JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
                JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
                WHERE m.name = TK.USERNAME AND r.name = 'ADMIN_ROLE'
            ) THEN 'Admin'
            
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_role_members rm
                JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
                JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
                WHERE m.name = TK.USERNAME AND r.name = 'GV_ROLE'
            ) THEN 'Giáo Viên'
            
            WHEN EXISTS (
                SELECT 1 
                FROM sys.database_role_members rm
                JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
                JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
                WHERE m.name = TK.USERNAME AND r.name = 'HS_ROLE'
            ) THEN 'Học Sinh'
            
            ELSE N'Chưa cấp quyền'
        END AS QuyenHienTaiTrongSQL
    FROM TAIKHOAN TK
    WHERE TK.TINHTRANG = N'Hoạt động'
END
GO

-- ---------------------------------------------------------------------------------------
-- NV1: KẾ HOẠCH SAO LƯU TỰ ĐỘNG VÀ PHỤC HỒI
-- ---------------------------------------------------------------------------------------

---------------------------------------SAO LƯU--------------------------------------------

-- >>>> GIAI ĐOẠN 1: Dữ liệu khởi tạo trước Full Backup (Thứ 7)
-- Nhập điểm Miệng, 15p cho HK1 (Chưa đầy đủ)

-- HS0001 (Giỏi): Toán, Văn, Anh, Lý, Hóa
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK1', '2024-2025', 'DM', 8.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK1', '2024-2025', 'D15', 7.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH002', 'HK1', '2024-2025', 'DM', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH003', 'HK1', '2024-2025', 'DM', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH004', 'HK1', '2024-2025', 'DM', 8.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH005', 'HK1', '2024-2025', 'DM', 8.5);

-- HS0002 (Khá): Toán, Văn, Anh, Lý, Hóa
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK1', '2024-2025', 'DM', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK1', '2024-2025', 'D15', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH002', 'HK1', '2024-2025', 'DM', 7.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH003', 'HK1', '2024-2025', 'DM', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH004', 'HK1', '2024-2025', 'DM', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH005', 'HK1', '2024-2025', 'DM', 7.0);

-- HS0003 (Xuất sắc): Toán, Văn, Anh, Lý, Hóa
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK1', '2024-2025', 'DM', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK1', '2024-2025', 'D15', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH002', 'HK1', '2024-2025', 'DM', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH003', 'HK1', '2024-2025', 'DM', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH004', 'HK1', '2024-2025', 'DM', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH005', 'HK1', '2024-2025', 'DM', 9.0);

-- HS0010 (Yếu/TB): Toán, Văn, Anh, Lý, Hóa
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK1', '2024-2025', 'DM', 4.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK1', '2024-2025', 'D15', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH002', 'HK1', '2024-2025', 'DM', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH003', 'HK1', '2024-2025', 'DM', 4.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH004', 'HK1', '2024-2025', 'DM', 4.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH005', 'HK1', '2024-2025', 'DM', 5.0);
GO

-- 1. Full Backup: T7, 18:00
BACKUP DATABASE QL_TRUONGC3
TO DISK = 'C:\HQT CSDL\Backup\QLTruongC3_Full.bak'
WITH 
    FORMAT,
    NAME = 'Full backup QL_TRUONGC3',
    SKIP,
    STATS = 5;
GO

-- >>>> GIAI ĐOẠN 2: Dữ liệu Thứ 2 (Trước Log Backup)
-- Nhập thêm điểm 1 Tiết (Giữa kỳ) cho HK1 cho 5 môn

-- HS0001
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK1', '2024-2025', 'D1T', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH002', 'HK1', '2024-2025', 'D1T', 8.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH003', 'HK1', '2024-2025', 'D1T', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH004', 'HK1', '2024-2025', 'D1T', 8.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH005', 'HK1', '2024-2025', 'D1T', 8.5);

-- HS0002
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK1', '2024-2025', 'D1T', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH002', 'HK1', '2024-2025', 'D1T', 7.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH003', 'HK1', '2024-2025', 'D1T', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH004', 'HK1', '2024-2025', 'D1T', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH005', 'HK1', '2024-2025', 'D1T', 7.0);

-- HS0003
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK1', '2024-2025', 'D1T', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH002', 'HK1', '2024-2025', 'D1T', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH003', 'HK1', '2024-2025', 'D1T', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH004', 'HK1', '2024-2025', 'D1T', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH005', 'HK1', '2024-2025', 'D1T', 9.0);

-- HS0010
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK1', '2024-2025', 'D1T', 4.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH002', 'HK1', '2024-2025', 'D1T', 5.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH003', 'HK1', '2024-2025', 'D1T', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH004', 'HK1', '2024-2025', 'D1T', 4.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH005', 'HK1', '2024-2025', 'D1T', 5.0);
GO

-- 2. Log Backup: T2 (Mon-Fri), mỗi 4 tiếng, từ 0h
BACKUP LOG QL_TRUONGC3
TO DISK = 'C:\HQT CSDL\Backup\QLTruongC3_Log.trn'
WITH 
    NAME = 'Log backup QL_TRUONGC3',
    SKIP,
    STATS = 5;
GO

-- >>>> GIAI ĐOẠN 3: Dữ liệu Thứ 3 (Trước Diff Backup)
-- Nhập điểm THI HK1 => KẾT THÚC HỌC KỲ 1 (Tất cả 4 học sinh 10A1 đều có đủ điểm thi 5 môn)

-- HS0001
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK1', '2024-2025', 'DTH', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH002', 'HK1', '2024-2025', 'DTH', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH003', 'HK1', '2024-2025', 'DTH', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH004', 'HK1', '2024-2025', 'DTH', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH005', 'HK1', '2024-2025', 'DTH', 9.0);

-- HS0002
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK1', '2024-2025', 'DTH', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH002', 'HK1', '2024-2025', 'DTH', 7.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH003', 'HK1', '2024-2025', 'DTH', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH004', 'HK1', '2024-2025', 'DTH', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH005', 'HK1', '2024-2025', 'DTH', 7.0);

-- HS0003
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK1', '2024-2025', 'DTH', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH002', 'HK1', '2024-2025', 'DTH', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH003', 'HK1', '2024-2025', 'DTH', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH004', 'HK1', '2024-2025', 'DTH', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH005', 'HK1', '2024-2025', 'DTH', 9.5);

-- HS0010
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK1', '2024-2025', 'DTH', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH002', 'HK1', '2024-2025', 'DTH', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH003', 'HK1', '2024-2025', 'DTH', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH004', 'HK1', '2024-2025', 'DTH', 4.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH005', 'HK1', '2024-2025', 'DTH', 5.5);
GO

-- 3. Diff Backup: T3, 18:00
BACKUP DATABASE QL_TRUONGC3
TO DISK = 'C:\HQT CSDL\Backup\QLTruongC3_Diff.bak'
WITH 
    DIFFERENTIAL,
    NAME = 'Differential backup QL_TRUONGC3',
    SKIP,
    STATS = 5;
GO

-- >>>> GIAI ĐOẠN 4: Dữ liệu Thứ 4 (Trước Log Backup)
-- BẮT ĐẦU HỌC KỲ 2
-- 1. Phân công giảng dạy HK2 cho 5 môn
INSERT INTO PHANCONG (MAGV, MALOP, MAMH, MAHK, MANAM) VALUES ('GV001', '10A1', 'MH001', 'HK2', '2024-2025');
INSERT INTO PHANCONG (MAGV, MALOP, MAMH, MAHK, MANAM) VALUES ('GV002', '10A1', 'MH002', 'HK2', '2024-2025');
INSERT INTO PHANCONG (MAGV, MALOP, MAMH, MAHK, MANAM) VALUES ('GV003', '10A1', 'MH003', 'HK2', '2024-2025');
INSERT INTO PHANCONG (MAGV, MALOP, MAMH, MAHK, MANAM) VALUES ('GV004', '10A1', 'MH004', 'HK2', '2024-2025');
INSERT INTO PHANCONG (MAGV, MALOP, MAMH, MAHK, MANAM) VALUES ('GV005', '10A1', 'MH005', 'HK2', '2024-2025');

-- 2. Nhập điểm khởi động HK2 (Miệng) cho 5 môn
-- HS0001
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK2', '2024-2025', 'DM', 7.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH002', 'HK2', '2024-2025', 'DM', 8.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH003', 'HK2', '2024-2025', 'DM', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH004', 'HK2', '2024-2025', 'DM', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH005', 'HK2', '2024-2025', 'DM', 8.0);

-- HS0002
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK2', '2024-2025', 'DM', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH002', 'HK2', '2024-2025', 'DM', 7.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH003', 'HK2', '2024-2025', 'DM', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH004', 'HK2', '2024-2025', 'DM', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH005', 'HK2', '2024-2025', 'DM', 6.0);

-- HS0003
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK2', '2024-2025', 'DM', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH002', 'HK2', '2024-2025', 'DM', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH003', 'HK2', '2024-2025', 'DM', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH004', 'HK2', '2024-2025', 'DM', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH005', 'HK2', '2024-2025', 'DM', 9.5);

-- HS0010
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK2', '2024-2025', 'DM', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH002', 'HK2', '2024-2025', 'DM', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH003', 'HK2', '2024-2025', 'DM', 5.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH004', 'HK2', '2024-2025', 'DM', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH005', 'HK2', '2024-2025', 'DM', 4.5);
GO

-- 4. Log Backup: T4 (Mon-Fri), mỗi 4 tiếng, từ 0h
BACKUP LOG QL_TRUONGC3
TO DISK = 'C:\HQT CSDL\Backup\QLTruongC3_Log.trn'
WITH 
    NAME = 'Log backup QL_TRUONGC3',
    SKIP,
    STATS = 5;
GO

-- >>>> GIAI ĐOẠN 5: Dữ liệu Thứ 5 (Trước Diff Backup)
-- Nhập điểm 1 Tiết HK2 cho 5 môn
-- HS0001
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK2', '2024-2025', 'D1T', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH002', 'HK2', '2024-2025', 'D1T', 8.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH003', 'HK2', '2024-2025', 'D1T', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH004', 'HK2', '2024-2025', 'D1T', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH005', 'HK2', '2024-2025', 'D1T', 8.0);

-- HS0002
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK2', '2024-2025', 'D1T', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH002', 'HK2', '2024-2025', 'D1T', 7.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH003', 'HK2', '2024-2025', 'D1T', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH004', 'HK2', '2024-2025', 'D1T', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH005', 'HK2', '2024-2025', 'D1T', 6.5);

-- HS0003
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK2', '2024-2025', 'D1T', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH002', 'HK2', '2024-2025', 'D1T', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH003', 'HK2', '2024-2025', 'D1T', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH004', 'HK2', '2024-2025', 'D1T', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH005', 'HK2', '2024-2025', 'D1T', 9.5);

-- HS0010
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK2', '2024-2025', 'D1T', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH002', 'HK2', '2024-2025', 'D1T', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH003', 'HK2', '2024-2025', 'D1T', 5.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH004', 'HK2', '2024-2025', 'D1T', 4.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH005', 'HK2', '2024-2025', 'D1T', 5.0);
GO

-- 5. Diff Backup: T5, 18:00
BACKUP DATABASE QL_TRUONGC3
TO DISK = 'C:\HQT CSDL\Backup\QLTruongC3_Diff.bak'
WITH 
    DIFFERENTIAL,
    NAME = 'Differential backup QL_TRUONGC3',
    SKIP,
    STATS = 5;
GO

-- >>>> GIAI ĐOẠN 6: Dữ liệu Thứ 6 (Trước Log Backup/Sự cố)
-- Nhập điểm THI HK2 => HOÀN THÀNH NĂM HỌC
-- Cả 4 học sinh lớp 10A1 sẽ có đầy đủ điểm để chạy hàm fn_TinhDiemTBNamHoc cho tất cả các môn

-- HS0001
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH001', 'HK2', '2024-2025', 'DTH', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH002', 'HK2', '2024-2025', 'DTH', 8.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH003', 'HK2', '2024-2025', 'DTH', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH004', 'HK2', '2024-2025', 'DTH', 9.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0001', 'MH005', 'HK2', '2024-2025', 'DTH', 8.5);

-- HS0002
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH001', 'HK2', '2024-2025', 'DTH', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH002', 'HK2', '2024-2025', 'DTH', 7.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH003', 'HK2', '2024-2025', 'DTH', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH004', 'HK2', '2024-2025', 'DTH', 6.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0002', 'MH005', 'HK2', '2024-2025', 'DTH', 6.5);

-- HS0003
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH001', 'HK2', '2024-2025', 'DTH', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH002', 'HK2', '2024-2025', 'DTH', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH003', 'HK2', '2024-2025', 'DTH', 10.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH004', 'HK2', '2024-2025', 'DTH', 9.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0003', 'MH005', 'HK2', '2024-2025', 'DTH', 9.0);

-- HS0010
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH001', 'HK2', '2024-2025', 'DTH', 4.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH002', 'HK2', '2024-2025', 'DTH', 6.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH003', 'HK2', '2024-2025', 'DTH', 5.5);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH004', 'HK2', '2024-2025', 'DTH', 4.0);
INSERT INTO DIEM (MAHS, MAMH, MAHK, MANAM, MALOAIDIEM, DIEM) VALUES ('HS0010', 'MH005', 'HK2', '2024-2025', 'DTH', 5.0);
GO

-- 6. Log Backup: T6 (Mon-Fri), mỗi 4 tiếng, từ 0h
BACKUP LOG QL_TRUONGC3
TO DISK = 'C:\HQT CSDL\Backup\QLTruongC3_Log.trn'
WITH 
    NAME = 'Log backup QL_TRUONGC3',
    SKIP,
    STATS = 5;
GO

----------------------------------------PHỤC HỒI--------------------------------------
--XẢY RA SỢ CỐ VÀO LÚC 15H NGÀY THỨ 6
backup log QL_TRUONGC3
to disk = 'C:\HQT CSDL\Backup\tailQLTruongC3.trn'
with norecovery

restore database QL_TRUONGC3
from disk = 'C:\HQT CSDL\Backup\QLTruongC3_Full.bak'
with norecovery

restore database QL_TRUONGC3
from disk = 'C:\HQT CSDL\Backup\QLTruongC3_Diff.bak'
with file = 2, norecovery

restore database QL_TRUONGC3
from disk = 'C:\HQT CSDL\Backup\QLTruongC3_Log.trn'
with file = 2, norecovery

restore database QL_TRUONGC3
from disk = 'C:\HQT CSDL\Backup\tailQLTruongC3.trn'
with 
	stopat = '2025-12-03T15:55:00', -- thời điểm muốn quay về
	recovery,
	stats = 5

--===================================================================
--                     Giải quyến tranh chấp
--===================================================================

---------------------------------------------------------------------------------------------------------------------
--1. TRANH CHẤP KHI XẾP THỜI KHÓA BIỂU
--   Giả sử Admin A xếp lớp 10A1 vào phòng P01 tiết 1. Admin B xếp lớp 10A2 vào phòng P01 tiết 1 cùng lúc.
--   Hệ thống kiểm tra thấy phòng trống cho cả 2, nhưng người sau sẽ bị lỗi DB crash thay vì thông báo nghiệp vụ.
--> Sử dụng TRANSACTION ISOLATION LEVEL SERIALIZABLE: Khi Transaction bắt đầu, nó sẽ khóa toàn bộ phạm vi dữ liệu liên quan.
--Không ai có thể chèn (Insert) dữ liệu mới vào khung giờ/phòng học đang được kiểm tra.
---------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROC PROC_TKB_THEM
(
    @MALOP CHAR(5),
    @MAMH CHAR(6),
    @MAGV CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @THU INT,
    @TIET INT,
    @MAPHONG CHAR(5)
)
AS
BEGIN
    -- [FIX]: Thiết lập mức cô lập cao nhất
    -- Đảm bảo không ai có thể chèn dữ liệu mới vào phạm vi đang kiểm tra
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Gọi hàm kiểm tra (Bây giờ đã được bảo vệ bởi Serializable)
        DECLARE @CHECK NVARCHAR(200);
        SET @CHECK = dbo.FUNC_KIEMTRA_TKB(@MALOP, @MAMH, @MAGV, @MANAM, @MAHK, @THU, @TIET, @MAPHONG);

        IF (@CHECK <> N'Hợp lệ')
        BEGIN
            -- Nếu không hợp lệ thì Rollback ngay và báo lỗi nghiệp vụ
            ROLLBACK TRANSACTION;
            RAISERROR(@CHECK, 16, 1);
            RETURN;
        END

        -- 2. Giả lập độ trễ để kiểm chứng (Đã an toàn nhờ Serializable)
        -- Trong thực tế bạn có thể bỏ dòng này
        WAITFOR DELAY '00:00:10'; 

        -- 3. Thực hiện Insert
        INSERT INTO THOIKHOABIEU(MALOP, MAMH, MAGV, MANAM, MAHK, THU, TIET, MAPHONG)
        VALUES (@MALOP, @MAMH, @MAGV, @MANAM, @MAHK, @THU, @TIET, @MAPHONG);

        COMMIT TRANSACTION;
        PRINT N'Thêm thời khóa biểu thành công!';
    END TRY
    BEGIN CATCH
        DECLARE @ERR NVARCHAR(4000) = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ERR,16,1);
    END CATCH
END
GO

---------------------------------------------------------------------------------------------------------------------
--2. TRANH CHẤP KHI SỬA TKB
--   Admin đang sửa TKB (Xóa cũ -> Thêm mới). Trong lúc chưa xong, Giáo viên vào xem TKB.
--   Giáo viên sẽ thấy TKB bị mất (trống trơn) trong khoảnh khắc đó.
--> Sử dụng TRANSACTION ISOLATION LEVEL SERIALIZABLE: Đảm bảo tính nhất quán (Consistency). Khi đang sửa, không ai đọc được dữ
--liệu cũ hoặc dữ liệu trống (giữa lúc Delete và Insert).
---------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROC PROC_TKB_SUA
(
    @MALOP CHAR(5),
    @MANAM CHAR(9),
    @MAHK CHAR(3),
    @THU INT,
    @TIET INT,
    @NEWMAMH CHAR(6),
    @NEWMAGV CHAR(5),
    @NEWMAPHONG CHAR(5)
)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- [MỨC CÔ LẬP CAO NHẤT]: Giữ khóa đến khi Commit
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Kiểm tra tồn tại
        -- Serializable sẽ giữ khóa trên dòng này, không ai sửa được trong lúc này
        IF NOT EXISTS (SELECT 1 FROM THOIKHOABIEU 
                       WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET)
        BEGIN
            RAISERROR(N'Không tìm thấy tiết học này để sửa!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Kiểm tra trùng lặp (Giáo viên, Phòng học)
        -- Serializable đảm bảo từ lúc kiểm tra đến lúc Insert, trạng thái GV/Phòng không bị thay đổi bởi người khác
        IF EXISTS (
            SELECT 1 FROM THOIKHOABIEU 
            WHERE MAGV = @NEWMAGV AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET
            AND MALOP <> @MALOP 
        )
        BEGIN
            RAISERROR(N'Giáo viên này đã có lịch dạy ở lớp khác vào tiết này!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (
            SELECT 1 FROM THOIKHOABIEU 
            WHERE MAPHONG = @NEWMAPHONG AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET
            AND MALOP <> @MALOP
        )
        BEGIN
            RAISERROR(N'Phòng học này đã có lớp khác học vào tiết này!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 3. Thực hiện Sửa (Delete -> Insert)
        -- Transaction sẽ giữ khóa X (Exclusive) từ lúc Delete.
        -- Người đọc bên ngoài sẽ bị block (chờ) cho đến khi Commit xong, 
        -- họ sẽ KHÔNG bao giờ thấy dữ liệu bị trống.
        
        DELETE FROM THOIKHOABIEU 
        WHERE MALOP = @MALOP AND MANAM = @MANAM AND MAHK = @MAHK AND THU = @THU AND TIET = @TIET;

        -- Giả lập xử lý chậm
        WAITFOR DELAY '00:00:10';

        INSERT INTO THOIKHOABIEU(MALOP, MAMH, MAGV, MANAM, MAHK, THU, TIET, MAPHONG)
        VALUES (@MALOP, @NEWMAMH, @NEWMAGV, @MANAM, @MAHK, @THU, @TIET, @NEWMAPHONG);

        COMMIT TRANSACTION;
        PRINT N'Cập nhật thời khóa biểu thành công (Protected by SERIALIZABLE)!';
    END TRY
    BEGIN CATCH
        DECLARE @ERR NVARCHAR(4000) = ERROR_MESSAGE();
        ROLLBACK TRANSACTION;
        RAISERROR(@ERR, 16, 1);
    END CATCH
END
GO

---------------------------------------------------------------------------------------------------------------------
--3. TRANH CHẤP KHI PHÂN LỚP HỌC SINH
--   Hai admin cùng phân lớp cho 1 học sinh mới vào lớp 10A1.
--   Cả 2 cùng thấy HS chưa có lớp -> Cùng Insert -> Lỗi trùng khóa chính.
--> Sử dụng 'SET TRANSACTION ISOLATION LEVEL SERIALIZABLE' kết hợp UPDLOCK: Với trường hợp Upsert (Kiểm tra rồi thêm), chỉ dùng Isolation Level thôi là chưa đủ
--để tránh Deadlock (Lỗi tắc nghẽn), ta vẫn cần thêm gợi ý 'UPDLOCK' để chuyển đổi khóa Shared thành Update ngay từ đầu.
---------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROC SP_PhanLopHocSinh
    @MAHS CHAR(6),
    @MALOP CHAR(5),
    @MANAM CHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- [MỨC CÔ LẬP CAO NHẤT]
    -- Đảm bảo Range Lock: "Khóa phạm vi kiểm tra, không ai chèn được dòng MAHS này vào".
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM HOCSINH WHERE MAHS = @MAHS) THROW 50001, N'Học sinh không tồn tại!', 1;
        IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP) THROW 50001, N'Lớp không tồn tại!', 1;

        DECLARE @Exists BIT = 0;
        
        -- Dù đã dùng SERIALIZABLE, ta vẫn nên thêm UPDLOCK để tránh Deadlock.
        -- Lý do: SERIALIZABLE cấp S-Lock (Khóa chia sẻ). 2 người cùng đọc -> Cùng có S-Lock.
        -- Khi cả 2 cùng Insert -> Cần X-Lock -> Đợi nhau nhả S-Lock -> Deadlock.
        -- UPDLOCK giúp lấy U-Lock ngay từ đầu (Chỉ 1 người được giữ).
        IF EXISTS (SELECT 1 FROM HOCSINH_NAMHOC WITH (UPDLOCK) 
                   WHERE MAHS = @MAHS AND MANAM = @MANAM)
        BEGIN
            SET @Exists = 1;
        END

        -- Giả lập độ trễ
        WAITFOR DELAY '00:00:10';

        IF @Exists = 1
        BEGIN
            UPDATE HOCSINH_NAMHOC
            SET MALOP = @MALOP
            WHERE MAHS = @MAHS AND MANAM = @MANAM;
            PRINT N'Đã cập nhật lớp thành công!';
        END
        ELSE
        BEGIN
            INSERT INTO HOCSINH_NAMHOC (MAHS, MANAM, MALOP)
            VALUES (@MAHS, @MANAM, @MALOP);
            PRINT N'Đã phân lớp mới thành công!';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO