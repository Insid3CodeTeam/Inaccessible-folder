program main32;

uses Windows, SysUtils; // Old Delphi like delphi 7.
//uses Winapi.Windows, System.SysUtils; // Modern Delphi like XE8.

type
  PLARGE_INTEGER = ^LARGE_INTEGER;
  PVOID = pointer;
  HANDLE = THANDLE;
  NTSTATUS = LongInt;

  TUnicodeString = packed record
    Length: Word;
    MaximumLength: Word;
    Buffer: PWideChar;
  end;
  UNICODE_STRING = TUnicodeString;
  PUNICODE_STRING = ^TUnicodeString;

  TObjectAttributes = packed record
    Length: ULONG;
    RootDirectory: THandle;
    ObjectName: PUNICODE_STRING;
    Attributes: ULONG;
    SecurityDescriptor: Pointer;
    SecurityQualityOfService: Pointer;
  end;
  OBJECT_ATTRIBUTES = TObjectAttributes;
  POBJECT_ATTRIBUTES = ^TObjectAttributes;

  TIoStatusBlock = packed record
    Status: NTSTATUS;
    Information: ULONG;
  end;
  IO_STATUS_BLOCK = TIoStatusBlock;
  PIO_STATUS_BLOCK = ^TIoStatusBlock;

const
  STATUS_SUCCESS = NTSTATUS(0);
  OBJ_CASE_INSENSITIVE = $00000040;
  FILE_ATTRIBUTE_HIDDEN = $00000002;
  FILE_DIRECTORY_FILE = $00000001;
  FILE_CREATE = $00000002;
  FILE_READ_DATA = $0001;
  FILE_WRITE_DATA = $0002;

function NtCreateFile(FileHandle: PHANDLE;
  DesiredAccess: ACCESS_MASK;
  ObjectAttributes: POBJECT_ATTRIBUTES;
  IoStatusBlock: PIO_STATUS_BLOCK;
  AllocationSize: PLARGE_INTEGER;
  FileAttributes: ULONG;
  ShareAccess: ULONG;
  CreateDisposition: ULONG;
  CreateOptions: ULONG;
  EaBuffer: PVOID;
  EaLength: ULONG): NTSTATUS; stdcall;
  external 'ntdll.dll' name 'NtCreateFile';

function NtDeleteFile(ObjectAttributes: POBJECT_ATTRIBUTES): NTSTATUS; stdcall;
  external 'ntdll.dll' name 'NtDeleteFile';

procedure RtlInitUnicodeString(DestinationString: PUNICODE_STRING; SourceString: PWideChar); stdcall;
  external 'ntdll.dll' name 'RtlInitUnicodeString';

function NtClose(Handle: THANDLE): NTSTATUS; stdcall;
  external 'ntdll.dll' name 'NtClose';

procedure InitializeObjectAttributes(p: POBJECT_ATTRIBUTES; n: PUNICODE_STRING; a: ULONG; r: HANDLE; s: PSECURITY_DESCRIPTOR);
begin
  p.Length := sizeof(OBJECT_ATTRIBUTES);
  p.RootDirectory := r;
  p.Attributes := a;
  p.ObjectName := n;
  p.SecurityDescriptor := s;
  p.SecurityQualityOfService := nil;
end;

procedure Report(NtStatus: NTSTATUS; msg: PAnsiChar; path: PWideChar);
var
  buffer: WideString;
  statusMsg: string;

begin
  statusMsg := 'FAILED!';
  if NtStatus = 0 then
    statusMsg := 'SUCCESS';

  buffer := format('Task: %s' + #13 + 'Path: %S' + #13 + 'Status: 0x%X (%s)',
    [msg, path, NtStatus, statusMsg]);

  if NtStatus = 0 then
    MessageBoxW(GetDesktopWindow(),
      PWideChar(buffer),
      'Report',
      MB_ICONINFORMATION)
  else
    MessageBoxW(GetDesktopWindow(),
      PWideChar(buffer),
      'Report',
      MB_ICONERROR);

end;

var
  ObjectAttributes: OBJECT_ATTRIBUTES;
  IoStatusBlock: IO_STATUS_BLOCK;
  hTarget: THandle;
  Status: NTSTATUS;
  FolderName: UNICODE_STRING;

  folders: array[0..2] of PWideChar = (
    '\??\C:\Winmend~Folder~Hidden',
    '\??\C:\Winmend~Folder~Hidden\...',
    '\??\C:\Winmend~Folder~Hidden\...\cn');

  x, z: byte;
begin

  for x := 0 to 2 do
  begin
    RtlInitUnicodeString(@FolderName, folders[x]);
    InitializeObjectAttributes(@ObjectAttributes, @FolderName, OBJ_CASE_INSENSITIVE, 0, nil);

    Status := NtCreateFile(@hTarget,
      FILE_READ_DATA + FILE_WRITE_DATA,
      @ObjectAttributes,
      @IoStatusBlock,
      nil,
      FILE_ATTRIBUTE_HIDDEN,
      FILE_SHARE_READ + FILE_SHARE_WRITE,
      FILE_CREATE,
      FILE_DIRECTORY_FILE,
      nil,
      0);

    Report(Status, 'Creating folder...', folders[x]);
    NtClose(hTarget);
  end;

  for z := 2 downto 0 do
  begin
    RtlInitUnicodeString(@FolderName, folders[z]);
    InitializeObjectAttributes(@ObjectAttributes, @FolderName, OBJ_CASE_INSENSITIVE, 0, nil);

    Status := NtDeleteFile(@ObjectAttributes);
    Report(Status, 'Deleting folder...', folders[z]);
  end;
end.

