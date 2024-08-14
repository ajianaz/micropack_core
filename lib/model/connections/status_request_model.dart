import 'failure_model.dart';

enum StatusRequest { NONE, LOADING, SUCCESS, EMPTY, ERROR }

class StatusRequestModel<T> {
  StatusRequest statusRequest = StatusRequest.NONE;
  T? data;
  FailureModel? failure;

  StatusRequestModel(
      {this.statusRequest = StatusRequest.NONE, this.data, this.failure});

  factory StatusRequestModel.fromStatus(StatusRequest status,
      {T? data, FailureModel? failure}) {
    switch (status) {
      case StatusRequest.LOADING:
        return StatusRequestModel.loading();
      case StatusRequest.SUCCESS:
        return StatusRequestModel.success(data);
      case StatusRequest.EMPTY:
        return StatusRequestModel.empty();
      case StatusRequest.ERROR:
        return StatusRequestModel.error(failure);
      case StatusRequest.NONE:
      default:
        return StatusRequestModel.empty();
    }
  }

  StatusRequestModel.loading() {
    statusRequest = StatusRequest.LOADING;
    data = null;
    failure = null;
  }

  StatusRequestModel.success(T? newData) {
    statusRequest = StatusRequest.SUCCESS;
    data = newData;
    failure = null;
  }

  StatusRequestModel.empty() {
    statusRequest = StatusRequest.EMPTY;
    data = null;
    failure = null;
  }

  StatusRequestModel.error(FailureModel? error) {
    statusRequest = StatusRequest.ERROR;
    data = null;
    failure = error;
  }

  // Method to handle different statuses with optional callbacks
  void handle({
    Function()? onLoading,
    Function(T? data)? onSuccess,
    Function()? onEmpty,
    Function(FailureModel? failure)? onError,
  }) {
    switch (statusRequest) {
      case StatusRequest.LOADING:
        if (onLoading != null) onLoading();
        break;
      case StatusRequest.SUCCESS:
        if (onSuccess != null) onSuccess(data);
        break;
      case StatusRequest.EMPTY:
      case StatusRequest.NONE: // Handle NONE as EMPTY
        if (onEmpty != null) onEmpty();
        break;
      case StatusRequest.ERROR:
        if (onError != null) onError(failure);
        break;
    }
  }
}
