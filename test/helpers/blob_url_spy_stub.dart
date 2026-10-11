/// Non-web stand-in for the web blob URL spy: there are no blob URLs.
int? Function() spyOnCreateObjectUrl() =>
    () => null;
