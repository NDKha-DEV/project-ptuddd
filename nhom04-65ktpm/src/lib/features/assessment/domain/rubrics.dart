import '../../exercises/data/models/exam_models.dart';

/// Một mức trong tiêu chí: điểm 0..3 kèm mô tả tiếng Việt.
class RubricLevel {
  const RubricLevel(this.points, this.descriptionVi);

  final int points;
  final String descriptionVi;
}

class RubricCriterion {
  const RubricCriterion({
    required this.id,
    required this.titleVi,
    required this.levels,
  });

  final String id;
  final String titleVi;
  final List<RubricLevel> levels;

  int get maxPoints => levels.last.points;
}

/// Rubric tự đánh giá Viết/Nói theo tiêu chí B1 (4 mức 0–3 cho mỗi tiêu chí).
class B1Rubrics {
  B1Rubrics._();

  static const writing = [
    RubricCriterion(
      id: 'task',
      titleVi: 'Hoàn thành yêu cầu đề',
      levels: [
        RubricLevel(0, 'Lạc đề hoặc bỏ gần hết các ý được yêu cầu.'),
        RubricLevel(1, 'Chỉ trả lời được 1 ý, các ý khác thiếu hoặc sai.'),
        RubricLevel(2, 'Có đủ các ý nhưng 1 ý còn sơ sài.'),
        RubricLevel(3, 'Đủ tất cả các ý, mỗi ý có chi tiết hoặc lý do.'),
      ],
    ),
    RubricCriterion(
      id: 'organisation',
      titleVi: 'Bố cục và liên kết',
      levels: [
        RubricLevel(0, 'Các câu rời rạc, không chia đoạn.'),
        RubricLevel(1, 'Có mở/kết nhưng ý nhảy cóc, ít từ nối.'),
        RubricLevel(2, 'Bố cục rõ, dùng từ nối cơ bản (and, but, because).'),
        RubricLevel(3, 'Mạch lạc, từ nối đa dạng (however, as a result...).'),
      ],
    ),
    RubricCriterion(
      id: 'vocabulary',
      titleVi: 'Từ vựng',
      levels: [
        RubricLevel(0, 'Vốn từ rất hạn chế, lỗi làm khó hiểu.'),
        RubricLevel(1, 'Lặp từ nhiều, đôi chỗ dùng sai nghĩa.'),
        RubricLevel(2, 'Đủ từ cho chủ đề, ít lỗi chính tả.'),
        RubricLevel(3, 'Từ đúng chủ đề, có collocation, hầu như không lỗi.'),
      ],
    ),
    RubricCriterion(
      id: 'grammar',
      titleVi: 'Ngữ pháp',
      levels: [
        RubricLevel(0, 'Lỗi ở hầu hết các câu.'),
        RubricLevel(1, 'Chỉ dùng câu đơn, lỗi thì động từ thường xuyên.'),
        RubricLevel(2, 'Có câu ghép/phức, vài lỗi nhưng không gây hiểu nhầm.'),
        RubricLevel(3, 'Cấu trúc đa dạng, chia thì đúng, rất ít lỗi.'),
      ],
    ),
  ];

  static const speaking = [
    RubricCriterion(
      id: 'fluency',
      titleVi: 'Độ trôi chảy',
      levels: [
        RubricLevel(0, 'Dừng lâu, không nói hết được câu.'),
        RubricLevel(1, 'Ngập ngừng nhiều, câu ngắn rời rạc.'),
        RubricLevel(2, 'Nói được liên tục, đôi lúc dừng để tìm từ.'),
        RubricLevel(3, 'Nói đủ thời gian, nhịp đều, tự sửa lỗi được.'),
      ],
    ),
    RubricCriterion(
      id: 'pronunciation',
      titleVi: 'Phát âm',
      levels: [
        RubricLevel(0, 'Người nghe gần như không hiểu.'),
        RubricLevel(1, 'Nhiều từ phát âm sai, thiếu âm cuối.'),
        RubricLevel(2, 'Dễ hiểu, còn vài lỗi trọng âm/âm cuối.'),
        RubricLevel(3, 'Rõ ràng, có ngữ điệu và nhấn trọng âm đúng.'),
      ],
    ),
    RubricCriterion(
      id: 'vocabulary',
      titleVi: 'Từ vựng',
      levels: [
        RubricLevel(0, 'Thiếu từ, phải chuyển sang tiếng Việt.'),
        RubricLevel(1, 'Lặp lại vài từ đơn giản.'),
        RubricLevel(2, 'Đủ từ để diễn đạt ý chính của chủ đề.'),
        RubricLevel(3, 'Từ đa dạng, diễn đạt lại được khi quên từ.'),
      ],
    ),
    RubricCriterion(
      id: 'grammar',
      titleVi: 'Ngữ pháp',
      levels: [
        RubricLevel(0, 'Chỉ nói được từ đơn lẻ.'),
        RubricLevel(1, 'Câu đơn, lỗi thì thường xuyên.'),
        RubricLevel(2, 'Có câu ghép, lỗi không làm hiểu sai.'),
        RubricLevel(3, 'Dùng đúng thì, có câu điều kiện/so sánh.'),
      ],
    ),
    RubricCriterion(
      id: 'content',
      titleVi: 'Nội dung và tương tác',
      levels: [
        RubricLevel(0, 'Không trả lời đúng câu hỏi.'),
        RubricLevel(1, 'Trả lời ngắn, không giải thích.'),
        RubricLevel(2, 'Trả lời đúng ý, có 1 lý do hoặc ví dụ.'),
        RubricLevel(3, 'Phát triển ý có lý do, ví dụ và kết luận.'),
      ],
    ),
  ];

  static List<RubricCriterion> forSkill(ExamSkill skill) =>
      skill == ExamSkill.speaking ? speaking : writing;
}
