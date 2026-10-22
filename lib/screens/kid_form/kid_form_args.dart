/// Arguments of the kid form (query parameters of its route). [index] edits an existing kid; [fromList]
/// means the kids list is already on the stack (pop back instead of opening it).
class KidFormArgs {
  const KidFormArgs({this.index, this.fromList = false});

  final int? index;
  final bool fromList;
}
