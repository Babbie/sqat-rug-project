package sqat.test;

import java.util.ArrayList;
import java.util.List;

public class complex {
	// this class has a method with a CC of 14.
	
	public void complexMethod() {
		if (true) {
			;
		}
		if (true) {
			;
		} else {
			;
		}
		switch (0) {
		case 0:	
			break;
		case 1:
			break;
		default:
			break;
		}
		do {
			;
		} while (false);
		while (true) {
			break;
		}
		for (int i = 0; i < 10; i++) {
			;
		}
		for (int i = 0;; i++) {
			break;
		}
		List<Integer> list = new ArrayList<Integer>();
		for (int i : list) {
			;
		}
		try {
			throw new Exception();
		} catch (Exception e) {
			
		} finally {
			
		}
		int i = true && false || true ? 0 : 1;
	}
}