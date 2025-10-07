class CommonApiDto {
  final String strCode;
  final String strType;

  CommonApiDto({
    required this.strCode,
    required this.strType,
  });

  Map<String, String> toQuery() => {
    "strCode": strCode,
    "strType": strType,
  };
}
