kaori-ins
=========
(06 Apr 2015)

KAORI-INS2014x - A Framework for Instance Search

KAORI-INS2014x Repo được sử dụng để tổ chức lại các code dùng cho các thí nghiệm trên TRECVID-INS datasets.

Tạo mới repos để khỏi ảnh hưởng đến repos cũ (kaori-ins/ins2014).

I. Working Environment

1. GitHub path: https://github.com/ledduy/kaori-ins2014x

2. Local dir: 
- (MacBook Pro): ˜/github-projects/kaori-ins2014x  - Dùng GitHub for Mac để quản lí repository. Clone kaori-ins2014x 

- (Desktop Windows): c:\Users\XXX\Documents\GitHub\kaori-ins2014x - Dùng GitHub for Windows để quản lí repository. 

3. IDE: Eclipse-PHP - Dùng chức năng Import để Import as existing project. 
- (Desktop Windows): Đặt lại đường dẫn workspace về c:\Users\XXX\Documents\GitHub

- Chọn chức năng Import/Git/Projects from Git/Existing local repos/
- Chọn Add/C:\Users\ledduy\Documents\GitHub --> Import existing projects
- Khi cần Commit thì dùng tính năng Commit để cập nhật vào local repos. Rồi từ đó sync lên server.

4. Exec server: p9c/ledduy/github-projects/kaori-ins2014x. Đơn giản là copy (clone, pull only).

II. Datasets
1. TV2014:
- 30 topics (9099-9128).
- 4 examples/topic.

2. TV2013: 
- 5 keyframes/sec.
- Keyframe size: 768x576
- 471,526 shots --> 2,245,924 keyframes (dùng 5KF/shot cho DPM).
- shot0_xxx --> development, excluded from the test set.
- 30 topics (9069-9098)
- BBC EastEnders, approximately 244 video files (totally 300 GB, 464 h).
- Submission format: <item seqNum="1" shotId="shot4324_2" />

================ CHECKED POINT ================

III. Experiments
1. RootDir: @per610a/das11f/ledduy/trecvid-ins-2014

2. keyframe-5
2.1. tv2014
- tv2014/test2014
- tv2014/query2014: chép toàn bộ dữ liệu gồm có .src, .mask, .showmask của các query images (4 images/query), 3 formats gồm .bmp (gốc của TRECVID), .png, và .bmp.
- tv2014/test2014-new

2.2. tv2013
- tv2013/query2013: chép toàn bộ dữ liệu gồm có .src, .mask, .showmask của các query images (4 images/query), 3 formats gồm .bmp (gốc của TRECVID), .png, và .bmp.

- tv2013/test2013:
ln -s /net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png/ test2013

lrwxrwxrwx 1 ledduy users 60 Aug  4 11:15 test2013 -> /net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png/

- tv2013/test2013-new
ln -s /net/per610a/export/das11f/ledduy/trecvid-ins-2013/keyframe-5/tv2013/test2013-new/ test2013-new

lrwxrwxrwx 1 ledduy users 82 Aug  4 11:17 test2013-new -> /net/per610a/export/das11f/ledduy/trecvid-ins-2013/keyframe-5/tv2013/test2013-new/

3. metadata/keyframe-5
3.1. tv2013
- ins.topics.2013.xml --> danh sách các topics cung cấp bởi TRECVID (tên gốc là ins.auto.topics.2013.xml)
- ins.search.qrels.tv2013 --> groundtruth cung cấp bởi TRECVID (sau khi có kết quả)
- ins.search.qrels.tv2013.csv --> thông tin về số lượng relevant shots của từng query.

3.2. tv2014
- ins.topics.2014.xml --> danh sách các topics cung cấp bởi TRECVID (tên gốc là ins.auto.topics.2014.xml)
- ins.search.qrels.tv2014 --> groundtruth cung cấp bởi TRECVID (sau khi có kết quả)
- ins.search.qrels.tv2014.csv --> thông tin về số lượng relevant shots của từng query.

4. feature/keyframe-5


IV. Diary
*** 03Aug2014 ***
1. Tạo môi trường làm việc trên MacBookPro, Desktop Windows, và Server

2. Tạo thư mục RootDir và các thư mục con. Đặt quyền 77x.

3. Cập nhật các tập tin cho KAORI-INS app config như là ksc-AppConfig.php, etc.

4. Xóa các tập tin dùng BoW (từ hệ thống KAORI-SECODE).
