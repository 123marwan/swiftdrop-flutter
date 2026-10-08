import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_model.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: []));

  void addToCart(MenuItemModel menuItem) {
    final existingIndex = state.items.indexWhere(
      (element) => element.menuItem.id == menuItem.id,
    );
    if (existingIndex != -1) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      emit(state.copyWith(items: updatedItems));
    } else {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems.add(CartItem(menuItem: menuItem, quantity: 1));
      emit(state.copyWith(items: updatedItems));
    }
  }

  void removeFromCart(int menuItemId) {
    final updatedItems = state.items
        .where((element) => element.menuItem.id != menuItemId)
        .toList();
    emit(state.copyWith(items: updatedItems));
  }

  void incrementQuantity(int menuItemId) {
    final existingIndex = state.items.indexWhere(
      (element) => element.menuItem.id == menuItemId,
    );
    if (existingIndex != -1) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
      emit(state.copyWith(items: updatedItems));
    }
  }

  void decrementQuantity(int menuItemId) {
    final existingIndex = state.items.indexWhere(
      (element) => element.menuItem.id == menuItemId,
    );
    if (existingIndex != -1) {
      final updatedItems = List<CartItem>.from(state.items);
      if (updatedItems[existingIndex].quantity > 1) {
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: updatedItems[existingIndex].quantity - 1,
        );
      } else {
        updatedItems.removeAt(existingIndex);
      }
      emit(state.copyWith(items: updatedItems));
    }
  }

  void clearCart() {
    emit(CartState(items: []));
  }
}