enum RoomStatus {
  available('Trống'),
  occupied('Đang ở'),
  maintenance('Bảo trì'),
  retired('Ngừng sử dụng');

  const RoomStatus(this.label);
  final String label;
}

/// Phòng cụ thể (bảng Phong): 101, 102, 201...
class Room {
  const Room({
    required this.id,
    required this.typeId,
    required this.number,
    required this.floor,
    this.note = '',
    this.status = RoomStatus.available,
  });

  final String id;
  final String typeId;
  final String number;
  final int floor;
  final String note;
  final RoomStatus status;

  /// Phòng bảo trì / ngừng sử dụng thì không nhận đặt mới
  bool get isBookable =>
      status == RoomStatus.available || status == RoomStatus.occupied;

  Room copyWith({RoomStatus? status}) => Room(
        id: id,
        typeId: typeId,
        number: number,
        floor: floor,
        note: note,
        status: status ?? this.status,
      );

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        typeId: json['typeId'] as String,
        number: json['number'] as String,
        floor: json['floor'] as int,
        note: json['note'] as String? ?? '',
        status: RoomStatus.values.byName(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'typeId': typeId,
        'number': number,
        'floor': floor,
        'note': note,
        'status': status.name,
      };
}
