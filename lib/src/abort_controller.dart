abstract interface class AbortSignal {
  bool get aborted;
  Function? get onAbort;
  set onAbort(Function? value);
}

class AbortController implements AbortSignal {
  bool _aborted = false;

  @override
  Function? onAbort;

  @override
  bool get aborted => _aborted;

  AbortSignal get signal => this;

  void abort() {
    if (!_aborted) {
      _aborted = true;
      onAbort?.call();
    }
  }
}
